class Api::V1::Widget::ConversationsController < Api::V1::Widget::BaseController
  include Events::Types
  before_action :render_not_found_if_empty, only: [:toggle_typing, :toggle_status, :set_custom_attributes, :destroy_custom_attributes]

  def index
    Rails.logger.info "[ConversationsController#index] === CONVERSATION INDEX START ==="
    Rails.logger.info "[ConversationsController#index] Visitor ID: #{visitor_id}"
    Rails.logger.info "[ConversationsController#index] Contact: #{@contact&.id}"
    Rails.logger.info "[ConversationsController#index] Contact inbox: #{@contact_inbox&.id}"
    
    # Handle case where user hasn't interacted with chat yet
    unless @contact_inbox.present?
      Rails.logger.info "[ConversationsController#index] No contact inbox - user hasn't opened chat yet"
      Rails.logger.info "[ConversationsController#index] === CONVERSATION INDEX END ==="
      @conversation = nil
      return
    end
    
    begin
      @conversation = conversation
      Rails.logger.info "[ConversationsController#index] Conversation found: #{@conversation.present?}, ID: #{@conversation&.id}"
      
      if @conversation.nil?
        Rails.logger.info "[ConversationsController#index] ℹ️ No conversation found - this is normal for users who haven't started chatting"
      else
        Rails.logger.info "[ConversationsController#index] ✅ Returning conversation #{@conversation.id} to frontend"
      end
    rescue => e
      Rails.logger.error "[ConversationsController#index] Error during conversation lookup: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      @conversation = nil
    end
    
    Rails.logger.info "[ConversationsController#index] === CONVERSATION INDEX END ==="
  end

  def create
    begin
      ActiveRecord::Base.transaction do
        process_update_contact
        
        # Check if we already have a conversation - if so, don't create a new one or fire webhook
        if conversation.present?
          @conversation = conversation
          
          # Add the message to existing conversation if message content provided
          if permitted_params[:message].present? && permitted_params[:message][:content].present?
            begin
              message_params_data = message_params
              if message_params_data.present? && !message_params_data.empty?
                @conversation.messages.create!(message_params_data)
              else
                Rails.logger.error "[ConversationsController] Invalid message params for existing conversation"
              end
            rescue => e
              Rails.logger.error "[ConversationsController] Failed to add message to existing conversation: #{e.message}"
              raise e
            end
          end
        else
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
          
          # Add the message to new conversation if message content provided
          if permitted_params[:message].present? && permitted_params[:message][:content].present?
            begin
              message_params_data = message_params
              if message_params_data.present? && !message_params_data.empty?
                @conversation.messages.create!(message_params_data)
              else
                Rails.logger.error "[ConversationsController] Invalid message params for new conversation"
              end
            rescue => e
              Rails.logger.error "[ConversationsController] Failed to add message to new conversation: #{e.message}"
              raise e
            end
          end
        end
        
        # TODO: Temporary fix for message type cast issue, since message_type is returning as string instead of integer
        @conversation.reload
      end
    rescue => e
      Rails.logger.error "[ConversationsController] Error in conversation creation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
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
    Rails.logger.info "[ConversationsController#update_last_seen] === UPDATE LAST SEEN START ==="
    Rails.logger.info "[ConversationsController#update_last_seen] Visitor ID: #{visitor_id}"
    Rails.logger.info "[ConversationsController#update_last_seen] Contact: #{@contact&.id}"
    Rails.logger.info "[ConversationsController#update_last_seen] Contact inbox: #{@contact_inbox&.id}"
    Rails.logger.info "[ConversationsController#update_last_seen] Auth token present: #{auth_token_params.present?}"
    
    # Handle case where user hasn't opened chat yet
    unless @contact_inbox.present?
      Rails.logger.info "[ConversationsController#update_last_seen] No contact inbox - user hasn't opened chat yet"
      head :ok  # Return success but do nothing
      return
    end
    
    begin
      current_conversation = conversation
      Rails.logger.info "[ConversationsController#update_last_seen] Conversation lookup result: #{current_conversation&.id || 'nil'}"
      
      if current_conversation.nil?
        Rails.logger.info "[ConversationsController#update_last_seen] ℹ️ No active conversation found - this is normal for users who haven't started chatting"
        head :ok  # Return success but do nothing
        return
      end

      Rails.logger.info "[ConversationsController#update_last_seen] ✅ Updating last seen for conversation: #{current_conversation.id}"
      current_conversation.contact_last_seen_at = DateTime.now.utc
      current_conversation.save!
      ::Conversations::UpdateMessageStatusJob.perform_later(current_conversation.id, current_conversation.contact_last_seen_at)
      Rails.logger.info "[ConversationsController#update_last_seen] === UPDATE LAST SEEN END ==="
      head :ok
    rescue => e
      Rails.logger.error "[ConversationsController#update_last_seen] Error during update_last_seen: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
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
    Rails.logger.info "[ConversationsController#toggle_typing] === TOGGLE TYPING START ==="
    Rails.logger.info "[ConversationsController#toggle_typing] Visitor ID: #{visitor_id}"
    Rails.logger.info "[ConversationsController#toggle_typing] Typing status: #{permitted_params[:typing_status]}"
    
    current_conversation = conversation
    Rails.logger.info "[ConversationsController#toggle_typing] Conversation lookup result: #{current_conversation&.id || 'nil'}"
    
    # Allow toggle_typing to work even without an active conversation
    if current_conversation.present?
      Rails.logger.info "[ConversationsController#toggle_typing] ✅ Processing typing event for conversation: #{current_conversation.id}"
      case permitted_params[:typing_status]
      when 'on'
        trigger_typing_event(CONVERSATION_TYPING_ON)
      when 'off'
        trigger_typing_event(CONVERSATION_TYPING_OFF)
      end
    else
      Rails.logger.warn "[ConversationsController#toggle_typing] ⚠️ No active conversation found - typing event skipped"
    end

    Rails.logger.info "[ConversationsController#toggle_typing] === TOGGLE TYPING END ==="
    head :ok
  end

  def toggle_status
    unless conversation.resolved?
      conversation.status = :resolved
      
      # Clear Redis mapping when conversation is resolved
      if visitor_id.present?
        VisitorConversationMapping.clear_visitor_data(visitor_id, @web_widget.website_token)
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
    Rails.configuration.dispatcher.dispatch(event, Time.zone.now, conversation: conversation, user: @contact)
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
