class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    conversation_id = params[:id] || params[:conversation_id]
    
    # Log the conversation lookup process
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] BaseController.conversation called - ID: #{conversation_id}, User: #{Current.user&.class}, Account: #{Current.account&.id}"
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] Call stack trace:"
    caller.first(8).each_with_index do |line, index|
      Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG]   #{index + 1}. #{line}"
    end
    
    # Find conversation by display_id
    @conversation = Current.account.conversations.find_by(display_id: conversation_id.to_i)
    
    if @conversation.nil?
      Rails.logger.error "[🔍 CONVERSATION LOOKUP DEBUG] Conversation not found with ID: #{conversation_id} in account #{Current.account&.id}"
      render json: { error: "Conversation not found with ID: #{conversation_id}" }, status: :not_found
      return
    end
    
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] Found conversation - ID: #{@conversation.id}, Display ID: #{@conversation.display_id}, Contact: #{@conversation.contact.id}, Inbox: #{@conversation.inbox.id}"
    
    # Special case for agent bots: bypass normal authorization if they're properly authenticated
    if Current.user.is_a?(AgentBot)
      # Check if the bot has access to any inbox in this account
      has_access = Current.user.agent_bot_inboxes.where(account_id: Current.account.id).exists?
      
      if !has_access
        Rails.logger.error "[🔍 CONVERSATION LOOKUP DEBUG] Agent bot not authorized for account #{Current.account.id}"
        render json: { error: "Agent bot not authorized for this account" }, status: :unauthorized
        return
      end
      
      Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] Agent bot authorized for conversation #{@conversation.id}"
      return
    end
    
    # Normal user authorization - wrap in begin/rescue to catch and log authorization errors
    begin
      authorize @conversation
      Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] User authorized for conversation #{@conversation.id}"
    rescue Pundit::NotAuthorizedError => e
      Rails.logger.error "[🔍 CONVERSATION LOOKUP DEBUG] User not authorized for conversation #{@conversation.id}: #{e.message}"
      render json: { error: "You are not authorized to perform this action" }, status: :unauthorized
    end
  end
end
