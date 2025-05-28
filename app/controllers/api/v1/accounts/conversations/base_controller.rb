class Api::V1::Accounts::Conversations::BaseController < Api::V1::Accounts::BaseController
  before_action :conversation

  private

  def conversation
    conversation_id = params[:conversation_id] || params[:id]
    
    Rails.logger.info "[CONVERSATION DEBUG] Looking up conversation with ID: #{conversation_id}"
    Rails.logger.info "[CONVERSATION DEBUG] Current user: #{Current.user&.class} (#{Current.user&.id})"
    Rails.logger.info "[CONVERSATION DEBUG] Request path: #{request.path}"
    Rails.logger.info "[CONVERSATION DEBUG] Request method: #{request.method}"
    
    # Try to find by display_id first (this is the correct approach)
    @conversation = Current.account.conversations.find_by!(display_id: conversation_id)
    
    Rails.logger.info "[CONVERSATION DEBUG] Found conversation - ID: #{@conversation.id}, Display ID: #{@conversation.display_id}, Contact: #{@conversation.contact.id}"
    
    # Try to find by actual ID to see if that's the issue
    conversation_by_id = Current.account.conversations.find_by(id: conversation_id.to_i)
    if conversation_by_id
      Rails.logger.error "[CONVERSATION DEBUG] FOUND conversation with actual ID: #{conversation_id} (display_id: #{conversation_by_id.display_id}) - n8n is using wrong ID!"
    end
    
    authorize @conversation.inbox, :show?
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[CONVERSATION DEBUG] Conversation not found with display_id: #{conversation_id}"
    Rails.logger.error "[CONVERSATION DEBUG] Error: #{e.message}"
    
    # Check if there's a conversation with this actual ID
    conversation_by_id = Current.account.conversations.find_by(id: conversation_id.to_i)
    if conversation_by_id
      Rails.logger.error "[CONVERSATION DEBUG] CRITICAL: Found conversation with actual ID #{conversation_id} but display_id is #{conversation_by_id.display_id}"
      Rails.logger.error "[CONVERSATION DEBUG] n8n should use display_id #{conversation_by_id.display_id} instead of actual ID #{conversation_id}"
    end
    
    raise
  end
end
