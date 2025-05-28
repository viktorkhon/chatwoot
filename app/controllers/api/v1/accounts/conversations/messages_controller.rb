class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  def index
    @messages = message_finder.perform
  end

  def create
    # Log the full call stack to identify what's triggering this API message creation
    Rails.logger.info "[🔍 N8N DEBUG] API MessagesController.create called"
    Rails.logger.info "[🔍 N8N DEBUG] Call stack trace:"
    caller.first(10).each_with_index do |line, index|
      Rails.logger.info "[🔍 N8N DEBUG]   #{index + 1}. #{line}"
    end
    
    Rails.logger.info "[🔍 N8N DEBUG] API message creation started - Conversation ID: #{@conversation.id}, Display ID: #{@conversation.display_id}, User: #{Current.user&.id || @resource&.class}"
    Rails.logger.info "[🔍 N8N DEBUG] Request URL params - conversation_id from URL: #{params[:conversation_id] || params[:id]}"
    Rails.logger.info "[🔍 N8N DEBUG] Request body params: #{params.except(:attachments, :controller, :action, :format, :conversation_id, :id).to_unsafe_h}"
    
    # CRITICAL: Verify this is not a duplicate conversation creation scenario
    if Current.user.is_a?(AgentBot) && params[:content].present?
      Rails.logger.info "[🔍 N8N DEBUG] Agent bot message creation - Bot ID: #{Current.user.id}, Bot Name: #{Current.user.name}"
      
      # Check if there are recent similar conversations that might indicate duplication
      similar_conversations = Current.account.conversations
        .joins(:contact)
        .where(contact: { id: @conversation.contact.id })
        .where(inbox_id: @conversation.inbox_id)
        .where('conversations.created_at > ?', 5.minutes.ago)
        .where.not(id: @conversation.id)
      
      if similar_conversations.exists?
        Rails.logger.warn "[🔍 N8N DEBUG] ⚠️  POTENTIAL DUPLICATE DETECTED - Found #{similar_conversations.count} recent conversations for same contact/inbox"
        similar_conversations.each do |conv|
          Rails.logger.warn "[🔍 N8N DEBUG] ⚠️  Similar conversation - ID: #{conv.id}, Display ID: #{conv.display_id}, Created: #{conv.created_at}"
        end
      else
        Rails.logger.info "[🔍 N8N DEBUG] ✅ No duplicate conversations detected for this contact/inbox combination"
      end
    end
    
    user = Current.user || @resource
    
    Rails.logger.info "[🔍 N8N DEBUG] Creating message via MessageBuilder - Conversation: #{@conversation.id}, User: #{user&.class}, Message Type: #{params[:message_type]}"
    
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
    
    Rails.logger.info "[🔍 N8N DEBUG] Message created successfully - Message ID: #{@message.id}, Conversation: #{@conversation.id}, Type: #{@message.message_type}"
    Rails.logger.info "[🔍 N8N DEBUG] ✅ n8n message creation completed successfully - no new conversation created"
  rescue StandardError => e
    Rails.logger.error "[🔍 N8N DEBUG] ❌ Error creating message: #{e.message}"
    Rails.logger.error "[🔍 N8N DEBUG] ❌ Error backtrace: #{e.backtrace.first(5).join(', ')}"
    raise
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
    
    Rails.logger.info "[🔍 CONVERSATION OVERRIDE DEBUG] MessagesController.conversation called - Requested ID: #{conversation_id}"
    Rails.logger.info "[🔍 CONVERSATION OVERRIDE DEBUG] Account: #{Current.account&.id}, User: #{Current.user&.class}"
    
    @conversation ||= Current.account.conversations.find_by!(display_id: conversation_id)
    
    Rails.logger.info "[🔍 CONVERSATION OVERRIDE DEBUG] ✅ Found conversation - ID: #{@conversation.id}, Display ID: #{@conversation.display_id}, Contact: #{@conversation.contact.id}"
    
    authorize @conversation.inbox, :show?
    
    Rails.logger.info "[🔍 CONVERSATION OVERRIDE DEBUG] ✅ Authorization passed for inbox: #{@conversation.inbox.id}"
    
    @conversation
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[🔍 CONVERSATION OVERRIDE DEBUG] ❌ Conversation not found with display_id: #{conversation_id}"
    raise
  rescue Pundit::NotAuthorizedError => e
    Rails.logger.error "[🔍 CONVERSATION OVERRIDE DEBUG] ❌ Authorization failed for inbox: #{@conversation&.inbox&.id} - #{e.message}"
    raise
  end
end
