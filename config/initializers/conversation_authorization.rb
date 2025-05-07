# This initializer adds improvements to agent bot authorization for conversations
# It patches the Conversation BaseController to better handle agent bot access

Rails.application.config.to_prepare do
  # Wait until the application is fully loaded 
  if defined?(Api::V1::Accounts::Conversations::BaseController)
    module AgentBotConversationAuthorization
      def conversation
        # Call the original method to get the conversation
        @original_conversation = super
        
        # If this is an agent bot and there's an authorization failure,
        # try a more lenient authorization approach
        if Current.user.is_a?(AgentBot) && @conversation.nil?
          conversation_id = params[:id] || params[:conversation_id]
          
          # Log the attempt
          Rails.logger.info("AgentBot #{Current.user.name} attempting to access conversation #{conversation_id}")
          
          # Find conversation by display_id
          @conversation = Current.account.conversations.find_by(display_id: conversation_id.to_i)
          
          if @conversation.present?
            # Check if the bot has access to any inbox in this account
            has_access = Current.user.agent_bot_inboxes.where(account_id: Current.account.id).exists?
            
            if has_access
              Rails.logger.info("Allowing AgentBot #{Current.user.name} access to conversation #{conversation_id}")
              return @conversation
            else
              Rails.logger.warn("AgentBot #{Current.user.name} denied access - no inbox permissions")
              render json: { error: 'Bot is not authorized for this account' }, status: :unauthorized
              return nil
            end
          else
            Rails.logger.warn("Conversation #{conversation_id} not found for AgentBot #{Current.user.name}")
            render json: { error: "Conversation not found with ID: #{conversation_id}" }, status: :not_found
            return nil
          end
        end
        
        @original_conversation
      end
    end
    
    # Include our module in the controller to enhance its behavior
    Api::V1::Accounts::Conversations::BaseController.prepend(AgentBotConversationAuthorization)
  end
end 