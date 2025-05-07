class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    conversation_id = params[:id] || params[:conversation_id]
    
    # Find conversation by display_id
    @conversation = Current.account.conversations.find_by(display_id: conversation_id.to_i)
    
    if @conversation.nil?
      render json: { error: "Conversation not found with ID: #{conversation_id}" }, status: :not_found
      return
    end
    
    # Special case for agent bots: bypass normal authorization if they're properly authenticated
    if Current.user.is_a?(AgentBot)
      # Check if the bot has access to any inbox in this account
      has_access = Current.user.agent_bot_inboxes.where(account_id: Current.account.id).exists?
      
      if !has_access
        render json: { error: "Agent bot not authorized for this account" }, status: :unauthorized
        return
      end
      
      return
    end
    
    # Normal user authorization - wrap in begin/rescue to catch and log authorization errors
    begin
      authorize @conversation
    rescue Pundit::NotAuthorizedError => e
      render json: { error: "You are not authorized to perform this action" }, status: :unauthorized
    end
  end
end
