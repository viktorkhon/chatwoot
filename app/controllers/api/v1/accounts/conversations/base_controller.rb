class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    conversation_id = params[:id] || params[:conversation_id]
    
    # Log the conversation lookup process with more detail
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] BaseController.conversation called - Requested ID: #{conversation_id}, User: #{Current.user&.class}, Account: #{Current.account&.id}"
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] Request params: #{params.except(:controller, :action, :format).to_unsafe_h}"
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] Call stack trace:"
    caller.first(8).each_with_index do |line, index|
      Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG]   #{index + 1}. #{line}"
    end
    
    # Find conversation by display_id
    @conversation = Current.account.conversations.find_by(display_id: conversation_id.to_i)
    
    if @conversation.nil?
      Rails.logger.error "[🔍 CONVERSATION LOOKUP DEBUG] ❌ Conversation NOT FOUND with display_id: #{conversation_id} in account #{Current.account&.id}"
      
      # Try to find by actual ID to see if that's the issue
      conversation_by_id = Current.account.conversations.find_by(id: conversation_id.to_i)
      if conversation_by_id
        Rails.logger.error "[🔍 CONVERSATION LOOKUP DEBUG] ❌ FOUND conversation with actual ID: #{conversation_id} (display_id: #{conversation_by_id.display_id}) - n8n is using wrong ID!"
        Rails.logger.error "[🔍 CONVERSATION LOOKUP DEBUG] ❌ n8n should use display_id: #{conversation_by_id.display_id} instead of actual id: #{conversation_id}"
      else
        Rails.logger.error "[🔍 CONVERSATION LOOKUP DEBUG] ❌ Conversation not found with either display_id OR actual id: #{conversation_id}"
      end
      
      render json: { error: "Conversation not found with ID: #{conversation_id}" }, status: :not_found
      return
    end
    
    Rails.logger.info "[🔍 CONVERSATION LOOKUP DEBUG] ✅ Found conversation - Actual ID: #{@conversation.id}, Display ID: #{@conversation.display_id}, Contact: #{@conversation.contact.id}, Inbox: #{@conversation.inbox.id}"
    
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
