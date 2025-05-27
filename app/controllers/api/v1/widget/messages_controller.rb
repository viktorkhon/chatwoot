class Api::V1::Widget::MessagesController < Api::V1::Widget::BaseController
  before_action :set_conversation, only: [:create]
  before_action :set_message, only: [:update]

  def index
    # Handle case where no conversation exists yet
    begin
      @conversation = conversation
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
    # Ensure we have a conversation first
    if conversation.nil?
      render json: { error: 'No conversation available' }, status: :unprocessable_entity
      return
    end

    # Ensure message params are valid
    message_params_data = message_params
    if message_params_data.empty?
      render json: { error: 'Invalid message data' }, status: :unprocessable_entity  
      return
    end

    begin
      @message = conversation.messages.new(message_params_data)
      build_attachment
      @message.save!
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: 'Message validation failed', message: e.message }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "[Widget] Error creating message: #{e.message}"
      render json: { error: 'Message creation failed' }, status: :internal_server_error
    end
  end

  def update
    if @message.content_type == 'input_email'
      @message.update!(submitted_email: contact_email)
      ContactIdentifyAction.new(
        contact: @contact,
        params: { email: contact_email, name: contact_name },
        retain_original_contact_name: true
      ).perform
    else
      @message.update!(message_update_params[:message])
    end
  rescue StandardError => e
    render json: { error: @contact.errors, message: e.message }.to_json, status: :internal_server_error
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
    current_conversation = conversation
    
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
    params.permit(message: [{ submitted_values: [:name, :title, :value, { csat_survey_response: [:feedback_message, :rating] }] }])
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
end
