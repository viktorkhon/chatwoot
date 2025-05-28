class Api::V1::Widget::MessagesController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create]
  before_action :set_message, only: [:update]

  def index
    # Handle case where no conversation exists yet
    begin
      Rails.logger.info "[Widget] 📨 MESSAGES INDEX CALLED"
      Rails.logger.info "[Widget] 📨 Messages Index - Request ID: #{request.request_id}"
      Rails.logger.info "[Widget] 📨 Messages Index - Request Method: #{request.method}"
      Rails.logger.info "[Widget] 📨 Messages Index - User Agent: #{request.headers['User-Agent']&.truncate(100)}"
      Rails.logger.info "[Widget] 📨 Messages Index - Referer: #{request.headers['Referer']}"
      Rails.logger.info "[Widget] 📨 Messages Index - Params: #{params.except(:controller, :action, :website_token).inspect}"
      Rails.logger.info "[Widget] 📨 Messages Index - Visitor ID: #{visitor_id}"
      
      # Use lightweight lookup for message operations to avoid Redis overhead
      @conversation = find_existing_conversation_without_redis
      Rails.logger.info "[Widget] Messages index - conversation: #{@conversation.class} (#{@conversation.inspect})"
      
      if @conversation.nil?
        @messages = []
        Rails.logger.info "[Widget] No conversation found for messages index, returning empty array"
      else
        finder = message_finder
        if finder && finder.respond_to?(:perform)
          @messages = finder.perform
          @messages = @messages.to_a if @messages.respond_to?(:to_a) # Ensure it's an array
          Rails.logger.info "[Widget] Found #{@messages.length} messages for conversation #{@conversation.id}"
        else
          @messages = []
          Rails.logger.warn "[Widget] Invalid message finder: #{finder.class}, returning empty array"
        end
      end
    rescue => e
      Rails.logger.error "[Widget] Error in messages index: #{e.message}"
      @conversation = nil
      @messages = []
    end
  end

  def create
    begin
      # Use lightweight lookup for message operations to avoid Redis overhead
      current_conversation = find_existing_conversation_without_redis
      Rails.logger.info "[Widget] Message create - conversation: #{current_conversation.class} (#{current_conversation.inspect})"
      
      if current_conversation.nil?
        render json: { error: 'No conversation available' }, status: :unprocessable_entity
        return
      end
      
      # Ensure we have a valid conversation object
      unless current_conversation.respond_to?(:messages)
        Rails.logger.error "[Widget] Invalid conversation object for message creation: #{current_conversation.class}"
        render json: { error: 'Invalid conversation state' }, status: :unprocessable_entity
        return
      end

      # Build message params with the conversation we already have
      message_params_data = build_message_params_for_conversation(current_conversation)
      Rails.logger.info "[Widget] Message params: #{message_params_data.inspect}"
      
      if message_params_data.empty?
        render json: { error: 'Invalid message data' }, status: :unprocessable_entity  
        return
      end

      @message = current_conversation.messages.new(message_params_data)
      build_attachment
      @message.save!
      Rails.logger.info "[Widget] Message created successfully: #{@message.id}"
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "[Widget] Message validation failed: #{e.message}"
      render json: { error: 'Message validation failed', message: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "[Widget] Error creating message: #{e.message}"
      Rails.logger.error "[Widget] Error backtrace: #{e.backtrace.first(5).join(', ')}"
      render json: { error: 'Message creation failed' }, status: :internal_server_error
    end
  end

  def update
    Rails.logger.info "[CONVERSATION DEBUG] ========== RAW PARAMS =========="
    Rails.logger.info "[CONVERSATION DEBUG] All params: #{params.inspect}"
    Rails.logger.info "[CONVERSATION DEBUG] Params except system: #{params.except(:controller, :action, :format, :website_token).inspect}"
    update_params = message_update_params
    Rails.logger.info "[CONVERSATION DEBUG] message_update_params result: #{update_params.inspect}"
    Rails.logger.info "[CONVERSATION DEBUG] message_update_params[:message]: #{update_params[:message].inspect}"
    
    # Message update should not trigger conversation lookups
    # The message already exists and has a conversation associated
    Rails.logger.info "[Widget] Message update - message: #{@message.id}, conversation: #{@message.conversation.id}"
    
    if @message.content_type == 'input_email'
      @message.update!(submitted_email: contact_email)
      ContactIdentifyAction.new(
        contact: @contact,
        params: { email: contact_email, name: contact_name },
        retain_original_contact_name: true
      ).perform
      
      Rails.logger.info "[CONVERSATION DEBUG] Email input message updated successfully"
    else
      Rails.logger.info "[CONVERSATION DEBUG] Update params for regular message: #{message_update_params[:message]}"
      
      @message.update!(message_update_params[:message])
      Rails.logger.info "[CONVERSATION DEBUG] Regular message updated successfully"
    end
    
  rescue StandardError => e
    Rails.logger.error "[CONVERSATION DEBUG] ========== MESSAGE UPDATE FAILED =========="
    Rails.logger.error "[CONVERSATION DEBUG] Error: #{e.message}"
    Rails.logger.error "[CONVERSATION DEBUG] Error class: #{e.class}"
    Rails.logger.error "[CONVERSATION DEBUG] Backtrace: #{e.backtrace.first(10).join(', ')}"
    
    render json: { error: 'Message update failed', message: e.message }, status: :internal_server_error
  end

  private

  def build_attachment
    return if params[:message][:attachments].blank?

    params[:message][:attachments].each do |uploaded_attachment|
      attachment = @message.attachments.new(
        account_id: @message.account_id,
        file: uploaded_attachment
      )

      attachment.file_type = helpers.file_type(uploaded_attachment&.content_type) if uploaded_attachment.is_a?(ActionDispatch::Http::UploadedFile)
    end
  end

  def set_conversation
    # Use lightweight lookup for message operations to avoid Redis overhead
    current_conversation = find_existing_conversation_without_redis
    
    if current_conversation.nil?
      Rails.logger.error "[MessagesController] ❌ NO_CONVERSATION: Visitor #{visitor_id}, Contact #{@contact_inbox&.source_id}"
      
      # Instead of creating a new conversation, return an error
      # Messages should only be sent to existing conversations
      render json: { 
        error: 'No active conversation found. Please start a conversation first.',
        code: 'NO_CONVERSATION'
      }, status: :unprocessable_entity
      return
    else
      @conversation = current_conversation
    end
  end

  def message_finder_params
    {
      filter_internal_messages: true,
      before: permitted_params[:before],
      after: permitted_params[:after]
    }
  end

  def message_finder
    return nil unless @conversation.present?
    
    finder = @message_finder ||= MessageFinder.new(@conversation, message_finder_params)
    Rails.logger.info "[Widget] Message finder created: #{finder.class} (#{finder.inspect})"
    finder
  end

  def message_update_params
    Rails.logger.info "[🔍 PARAMS DEBUG] ========== MESSAGE_UPDATE_PARAMS STARTED =========="
    Rails.logger.info "[🔍 PARAMS DEBUG] Raw params: #{params.inspect}"
    Rails.logger.info "[🔍 PARAMS DEBUG] params[:message]: #{params[:message].inspect}"
    Rails.logger.info "[🔍 PARAMS DEBUG] params[:message].present?: #{params[:message].present?}"
    
    if params[:message].present?
      Rails.logger.info "[🔍 PARAMS DEBUG] params[:message] keys: #{params[:message].keys.inspect}" if params[:message].respond_to?(:keys)
      Rails.logger.info "[🔍 PARAMS DEBUG] params[:message][:submitted_values]: #{params[:message][:submitted_values].inspect}" if params[:message].respond_to?(:dig)
    end
    
    params.permit(message: [{ submitted_values: [:name, :title, :value, { csat_survey_response: [:feedback_message, :rating] }] }])
    
    Rails.logger.info "[🔍 PARAMS DEBUG] Permitted params: #{permitted_params.inspect}"
    Rails.logger.info "[🔍 PARAMS DEBUG] Permitted params[:message]: #{permitted_params[:message].inspect}"
    Rails.logger.info "[🔍 PARAMS DEBUG] ========== MESSAGE_UPDATE_PARAMS COMPLETED =========="
    
    permitted_params
  end

  def permitted_params
    # timestamp parameter is used in create conversation method
    params.permit(:id, :before, :after, :website_token, :visitor_id, contact: [:name, :email], 
                  message: [:content, :referer_url, :page_url, :page_title, :timestamp, :echo_id, :reply_to, 
                           { content_attributes: { page_info: [:referer_url, :page_url, :page_title] } }])
  end

  def set_message
    @message = @web_widget.inbox.messages.find(permitted_params[:id])
  end

  def build_message_params_for_conversation(conversation)
    message_data = permitted_params[:message] || {}
    
    # Ensure we have a valid conversation object
    unless conversation.respond_to?(:account_id) && conversation.respond_to?(:inbox_id)
      Rails.logger.error "[Widget] Invalid conversation object for message_params: #{conversation.class}"
      return {}
    end
    
    return {} unless conversation.account_id && conversation.inbox_id
    
    {
      account_id: conversation.account_id,
      sender: @contact,
      content: message_data[:content],
      inbox_id: conversation.inbox_id,
      content_attributes: build_message_content_attributes(message_data),
      echo_id: message_data[:echo_id],
      message_type: :incoming
    }
  end

  def build_message_content_attributes(message_data)
    {
      in_reply_to: message_data[:reply_to],
      page_info: {
        page_url: message_data[:page_url],
        page_title: message_data[:page_title],
        referer_url: message_data[:referer_url]
      }.compact
    }.compact
  end
end
