class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  def index
    @messages = message_finder.perform
  end

  def create
    Rails.logger.info "[CONVERSATION DEBUG] API MessagesController.create called - User: #{Current.user&.class} (#{Current.user&.id}), Conversation: #{@conversation.id}"
    
    # Check if this is n8n calling the API
    if Current.user.is_a?(AgentBot)
      Rails.logger.info "[CONVERSATION DEBUG] n8n API call detected - adding message to existing conversation #{@conversation.id}"
      
      # Check for duplicate conversations for the same contact
      contact_conversations = @conversation.contact.conversations.where(inbox: @conversation.inbox).order(created_at: :desc).limit(3)
      if contact_conversations.count > 1
        Rails.logger.warn "[CONVERSATION DEBUG] POTENTIAL DUPLICATE: Contact #{@conversation.contact.id} has #{contact_conversations.count} conversations in this inbox:"
        contact_conversations.each_with_index do |conv, index|
          Rails.logger.warn "[CONVERSATION DEBUG]   #{index + 1}. ID: #{conv.id}, Display ID: #{conv.display_id}, Status: #{conv.status}, Created: #{conv.created_at}"
        end
      end
    end
    
    @message = Messages::MessageBuilder.new(Current.user, @conversation, message_params).perform
    
    Rails.logger.info "[CONVERSATION DEBUG] Message created successfully - Message ID: #{@message.id}, Conversation: #{@conversation.id}, Type: #{@message.message_type}"
    
    if Current.user.is_a?(AgentBot)
      Rails.logger.info "[CONVERSATION DEBUG] n8n message creation completed successfully - no new conversation created"
    end
  end

  def destroy
    ActiveRecord::Base.transaction do
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  end

  def retry
    return if message.blank?

    message.update!(status: :sent, content_attributes: {})
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: permitted_params[:target_language]
    ).perform

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations)
    end

    render json: { content: translated_content }
  end

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language)
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end
  
  # Override the conversation method from BaseController to support both :id and :conversation_id parameters
  def conversation
    conversation_id = params[:conversation_id] || params[:id]
    
    Rails.logger.info "[CONVERSATION DEBUG] MessagesController.conversation called - Requested ID: #{conversation_id}"
    Rails.logger.info "[CONVERSATION DEBUG] Account: #{Current.account&.id}, User: #{Current.user&.class}"
    
    @conversation ||= Current.account.conversations.find_by!(display_id: conversation_id)
    
    Rails.logger.info "[CONVERSATION DEBUG] ✅ Found conversation - ID: #{@conversation.id}, Display ID: #{@conversation.display_id}, Contact: #{@conversation.contact.id}"
    
    authorize @conversation.inbox, :show?
    
    Rails.logger.info "[CONVERSATION DEBUG] ✅ Authorization passed for inbox: #{@conversation.inbox.id}"
    
    @conversation
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[CONVERSATION DEBUG] ❌ Conversation not found with display_id: #{conversation_id}"
    raise
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error "[CONVERSATION DEBUG] ❌ Authorization failed for inbox: #{@conversation&.inbox&.id} - #{e.message}"
    raise
  end
end
