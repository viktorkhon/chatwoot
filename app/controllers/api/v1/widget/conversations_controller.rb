class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :render_not_found_if_empty, only: [:toggle_status, :set_custom_attributes, :destroy_custom_attributes]

  def index
    # Handle case where user hasn't interacted with chat yet
    unless @contact_inbox.present?
      @conversation = nil
      return
    end
    
    begin
      @conversation = conversation
      
      if @conversation.nil?
        Rails.logger.info "[Widget] No conversation found for visitor: #{visitor_id}"
      end
    rescue => e
      Rails.logger.error "[Widget] Error during conversation lookup: #{e.message}"
      @conversation = nil
    end
  end

  def create
    begin
      ActiveRecord::Base.transaction do
        Rails.logger.info "[Widget] 🔍 CONVERSATION CREATE - Request initiated"
        Rails.logger.info "[Widget] 🔍 CONVERSATION CREATE - Referer: #{request.headers['Referer']}"
        Rails.logger.info "[Widget] 🔍 CONVERSATION CREATE - X-Visitor-ID: #{request.headers['X-Visitor-ID']}"
        Rails.logger.info "[Widget] 🔍 CONVERSATION CREATE - Has message content: #{permitted_params[:message]&.[](:content).present?}"
        Rails.logger.info "[Widget] 🔍 CONVERSATION CREATE - Initial contact: #{@contact&.id}"
        Rails.logger.info "[Widget] 🔍 CONVERSATION CREATE - Request source: #{request.headers['User-Agent']&.include?('chatwoot') ? 'Widget Frontend' : 'External API/Webhook'}"
        
        process_update_contact
        
        # Check if we already have a conversation - if so, don't create a new one or fire webhook
        existing_conversation = conversation
        
        if existing_conversation.present?
          Rails.logger.info "[Widget] ✅ Using existing conversation #{existing_conversation.id}"
          @conversation = existing_conversation
          
          # Add the message to existing conversation if message content provided
          if permitted_params[:message].present? && permitted_params[:message][:content].present?
            begin
              message_params_data = message_params
              if message_params_data.present? && !message_params_data.empty?
                @conversation.messages.create!(message_params_data)
              end
            rescue => e
              raise e
            end
          end
        else
          Rails.logger.warn "[Widget] ⚠️ CREATING NEW CONVERSATION for visitor: #{visitor_id}"
          
          # Store page info in Redis before creating conversation (for incognito users)
          if visitor_id.present? && permitted_params[:message].present?
            page_info = {
              page_url: permitted_params[:message][:page_url],
              page_title: permitted_params[:message][:page_title],
              referer_url: permitted_params[:message][:referer_url]
            }.compact
            
            if page_info.any?
              VisitorConversationMapping.set_page_info_for_visitor(visitor_id, @web_widget.website_token, page_info)
            end
          end
          
          # Create new conversation (this will trigger webhook)
          @conversation = create_conversation
          Rails.logger.info "[Widget] ✅ NEW conversation created: #{@conversation.id}"
          
          # Add the message to new conversation if message content provided
          if permitted_params[:message].present? && permitted_params[:message][:content].present?
            begin
              message_params_data = message_params
              if message_params_data.present? && !message_params_data.empty?
                @conversation.messages.create!(message_params_data)
              end
            rescue => e
              Rails.logger.error "[Widget] Failed to add message to new conversation: #{e.message}"
              raise e
            end
          end
        end
        
        # TODO: Temporary fix for message type cast issue, since message_type is returning as string instead of integer
        @conversation.reload
      end
    rescue => e
      Rails.logger.error "[Widget] Error in conversation creation: #{e.message}"
      render json: { error: 'Conversation creation failed' }, status: :internal_server_error
    end
  end

  def process_update_contact
    @contact = ContactIdentifyAction.new(
      contact: @contact,
      params: { email: contact_email, phone_number: contact_phone_number, name: contact_name },
      retain_original_contact_name: true,
      discard_invalid_attrs: true
    ).perform
  end

  def update_last_seen
    # Handle case where user hasn't opened chat yet
    unless @contact_inbox.present?
      head :ok  # Return success but do nothing
      return
    end
    
    begin
      current_conversation = conversation
      
      if current_conversation.nil?
        head :ok  # Return success but do nothing
        return
      end

      current_conversation.contact_last_seen_at = DateTime.now.utc
      current_conversation.save!
      ::Conversations::UpdateMessageStatusJob.perform_later(current_conversation.id, current_conversation.contact_last_seen_at)
      head :ok
    rescue => e
      Rails.logger.error "[Widget] Error during update_last_seen: #{e.message}"
      head :ok  # Return success to avoid breaking the frontend
    end
  end

  def transcript
    if conversation.present? && conversation.contact.present? && conversation.contact.email.present?
      ConversationReplyMailer.with(account: conversation.account).conversation_transcript(
        conversation,
        conversation.contact.email
      )&.deliver_later
    end
    head :ok
  end

  def toggle_typing
    begin
      current_conversation = conversation
      
      # Allow toggle_typing to work even without an active conversation
      # Ensure we have a valid conversation object, not just a truthy value
      if current_conversation.present? && current_conversation.respond_to?(:id)
        case permitted_params[:typing_status]
        when 'on'
          trigger_typing_event(CONVERSATION_TYPING_ON)
        when 'off'
          trigger_typing_event(CONVERSATION_TYPING_OFF)
        end
      else
        Rails.logger.info "[Widget] Toggle typing called without valid conversation: #{current_conversation.class}"
      end
    rescue => e
      Rails.logger.error "[Widget] Error in toggle_typing: #{e.message}"
    end

    head :ok
  end

  def toggle_status
    unless conversation.resolved?
      conversation.status = :resolved
      
      # Clear Redis mapping when conversation is resolved
      if visitor_id.present?
        VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
      end
      
      # Clear webwidget_triggered session to allow new webhook on next chat session
      if @contact_inbox.present?
        session_key = "webwidget_triggered:#{@contact_inbox.source_id}:#{@web_widget.inbox.account_id}"
        bot_session_key = "webwidget_triggered_bot:#{@contact_inbox.source_id}:#{@web_widget.inbox.account_id}"
        begin
          $alfred.with do |conn|
            conn.del(session_key)
            conn.del(bot_session_key)
          end
        rescue => e
          Rails.logger.error "[Widget] Redis error clearing webwidget_triggered sessions: #{e.message}"
        end
      end
      
      conversation.save!
      
      # Clear any existing cookies
      cookies.delete(:cw_conversation)
      cookies.delete(:cw_contact)
    end
    head :ok
  end

  def set_custom_attributes
    conversation.update!(custom_attributes: permitted_params[:custom_attributes])
  end

  def destroy_custom_attributes
    conversation.custom_attributes = conversation.custom_attributes.excluding(params[:custom_attribute])
    conversation.save!
    render json: conversation
  end

  private

  def trigger_typing_event(event)
    current_conversation = conversation
    # Only dispatch if we have a valid conversation object
    if current_conversation.respond_to?(:id)
      Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: current_conversation, user: @contact)
    else
      Rails.logger.warn "[Widget] Skipping typing event dispatch - invalid conversation: #{current_conversation.class}"
    end
  end

  def render_not_found_if_empty
    return head :not_found if conversation.nil?
  end

  def permitted_params
    params.permit(:id, :typing_status, :website_token, :email, :visitor_id, contact: [:name, :email, :phone_number],
                                                               message: [:content, :referer_url, :page_url, :page_title, :timestamp, :echo_id],
                                                               custom_attributes: {})
  end
end
