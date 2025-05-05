class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    conversation_id = params[:id] || params[:conversation_id]
    
    # Enhanced debugging information
    Rails.logger.info("BaseController#conversation - Conversation lookup attempt")
    Rails.logger.info("Params: #{params.inspect}")
    Rails.logger.info("Looking up conversation with display_id: #{conversation_id}, account_id: #{Current.account.id}")
    
    # Debug check if the conversation exists by ID
    conversation_check = Current.account.conversations.where(display_id: conversation_id.to_i).exists?
    Rails.logger.info("Conversation with display_id #{conversation_id} exists? #{conversation_check}")
    
    # Find conversation by display_id
    @conversation = Current.account.conversations.find_by(display_id: conversation_id.to_i)
    
    if @conversation.nil?
      Rails.logger.error("CONVERSATION NOT FOUND - display_id: #{conversation_id}, account_id: #{Current.account.id}")
      render json: { error: "Conversation not found with ID: #{conversation_id}" }, status: :not_found
      return
    end
    
    Rails.logger.info("Conversation found: #{@conversation.id} (internal) / #{@conversation.display_id} (display)")
    
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
