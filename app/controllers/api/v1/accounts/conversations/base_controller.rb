class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    conversation_id = params[:id] || params[:conversation_id]
    
    # Log debugging information
    Rails.logger.info("Looking up conversation with display_id: #{conversation_id}, account_id: #{Current.account.id}, params: #{params.inspect}")
    
    # Find conversation by display_id
    @conversation = Current.account.conversations.find_by(display_id: conversation_id.to_i)
    
    if @conversation.nil?
      Rails.logger.error("Conversation not found with display_id: #{conversation_id}, account_id: #{Current.account.id}")
      render json: { error: "Conversation not found with ID: #{conversation_id}" }, status: :not_found
      return
    end
    
    # Special case for agent bots: bypass normal authorization if they're properly authenticated
    if Current.user.is_a?(AgentBot)
      # Check if the bot has access to any inbox in this account
      has_access = Current.user.agent_bot_inboxes.where(account_id: Current.account.id).exists?
      
      if !has_access
        Rails.logger.error("Agent bot not authorized for account: #{Current.account.id}")
        render json: { error: "Agent bot not authorized for this account" }, status: :unauthorized
        return
      end
      
      # Bot has access to account, allow the operation
      Rails.logger.info("Agent bot authorized for conversation: #{conversation_id}")
      return
    end
    
    # Normal user authorization
    authorize @conversation
  end
end
