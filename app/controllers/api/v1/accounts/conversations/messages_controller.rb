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
    
    Rails.logger.info "[🔍 N8N DEBUG] API message creation started - Conversation ID: #{@conversation.id}, User: #{Current.user&.id || @resource&.class}, Params: #{params.except(:attachments).to_unsafe_h}"
    
    user = Current.user || @resource
    
    Rails.logger.info "[🔍 N8N DEBUG] Creating message via MessageBuilder - Conversation: #{@conversation.id}, User: #{user&.class}, Message Type: #{params[:message_type]}"
    
    mb = Messages::MessageBuilder.new(user, @conversation, params)
    @message = mb.perform
    
    Rails.logger.info "[🔍 N8N DEBUG] Message created successfully - Message ID: #{@message.id}, Conversation: #{@conversation.id}, Type: #{@message.message_type}"
  rescue StandardError => e
    Rails.logger.error "[🔍 N8N DEBUG] Message creation failed - Conversation: #{@conversation.id}, Error: #{e.message}, Backtrace: #{e.backtrace.first(5).join(', ')}"
    render_could_not_create_error(e.message)
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
    @conversation ||= Current.account.conversations.find_by!(display_id: conversation_id)
    authorize @conversation.inbox, :show?
  end
end
