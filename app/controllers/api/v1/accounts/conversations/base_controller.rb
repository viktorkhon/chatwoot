class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    conversation_id = params[:id] || params[:conversation_id]
    
    # Log debugging information
    Rails.logger.info("Looking up conversation with display_id: #{conversation_id}, account_id: #{Current.account.id}, params: #{params.inspect}")
    
    # Try to find the conversation, handling both string and integer IDs
    @conversation = Current.account.conversations.find_by(display_id: conversation_id.to_i)
    
    if @conversation.nil?
      Rails.logger.error("Conversation not found with display_id: #{conversation_id}, account_id: #{Current.account.id}")
      render json: { error: 'Conversation not found' }, status: :not_found
      return
    end
    
    authorize @conversation
  end
end
