class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook)
    # Ensure page_info is always included in the payload
    enriched_payload = ensure_page_info_in_payload(payload)
    
    Webhooks::Trigger.execute(url, enriched_payload, webhook_type)
  end

  private

  def ensure_page_info_in_payload(payload)
    # Create a copy to modify
    enriched_payload = payload.dup
    
    # Ensure custom_attributes exists
    enriched_payload[:custom_attributes] ||= {}
    
    # Check if we already have page URL in custom_attributes
    return enriched_payload if enriched_payload[:custom_attributes]['page_url'].present?
    
    # Find conversation to get page info
    conversation = find_conversation_from_payload(enriched_payload)
    
    if conversation && conversation.custom_attributes.present? && conversation.custom_attributes['page_url'].present?
      # Copy page URL info from conversation custom_attributes
      enriched_payload[:custom_attributes]['page_url'] = conversation.custom_attributes['page_url']
      enriched_payload[:custom_attributes]['page_title'] = conversation.custom_attributes['page_title'] if conversation.custom_attributes['page_title'].present?
      enriched_payload[:custom_attributes]['referer_url'] = conversation.custom_attributes['referer_url'] if conversation.custom_attributes['referer_url'].present?
    end
    
    # Remove any old style page info
    enriched_payload.delete(:visitor_page)
    enriched_payload.delete(:page_url)
    enriched_payload.delete(:page_title)
    enriched_payload.delete(:referer_url)
    
    enriched_payload
  end
  
  def find_conversation_from_payload(payload)
    conversation = nil
    
    # Option 1: Direct conversation_id
    if payload[:conversation_id].present?
      conversation = Conversation.find_by(id: payload[:conversation_id])
    
    # Option 2: Conversation object with ID
    elsif payload[:conversation].present? && payload[:conversation][:id].present?
      conversation = Conversation.find_by(id: payload[:conversation][:id])
      
    # Option 3: Look for message with conversation
    elsif payload[:id].present? && payload[:message_type].present?
      message = Message.find_by(id: payload[:id])
      conversation = message.conversation if message&.conversation.present?
    end
    
    conversation
  end
end
