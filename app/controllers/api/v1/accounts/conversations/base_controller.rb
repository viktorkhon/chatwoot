class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    begin
      conversation_id = params[:id] || params[:conversation_id]
      Rails.logger.info("Looking for conversation with display_id: #{conversation_id} in account #{Current.account.id}")
      
      # Check if conversation exists before trying to find it
      exists = Current.account.conversations.where(display_id: conversation_id).exists?
      Rails.logger.info("Conversation exists? #{exists}")
      
      @conversation = Current.account.conversations.find_by!(display_id: conversation_id)
      authorize @conversation
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("Conversation not found: #{e.message}")
      render json: { error: "Conversation not found with ID: #{conversation_id}" }, status: :not_found
    end
  end
end
