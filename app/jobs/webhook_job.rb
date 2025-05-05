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
    # Return original payload if already has page info
    return payload if payload[:page_url].present? || payload[:referer_url].present? || payload[:visitor_page].present?
    
    # Create a copy to modify
    enriched_payload = payload.dup
    
    # Check if we have a conversation to extract page info from
    if enriched_payload[:conversation_id].present?
      conversation = Conversation.find_by(id: enriched_payload[:conversation_id])
      enrich_from_conversation(enriched_payload, conversation) if conversation
    elsif enriched_payload[:conversation].present? && enriched_payload[:conversation][:id].present?
      conversation = Conversation.find_by(id: enriched_payload[:conversation][:id])
      enrich_from_conversation(enriched_payload, conversation) if conversation
    end
    
    enriched_payload
  end
  
  def enrich_from_conversation(payload, conversation)
    return payload unless conversation.present?
    
    # Only proceed if we have a page_url - that's the most important piece
    if conversation.custom_attributes.present? && conversation.custom_attributes['page_url'].present?
      # Add visitor page info
      payload[:visitor_page] ||= {}
      payload[:visitor_page][:page_url] = conversation.custom_attributes['page_url']
      payload[:page_url] = conversation.custom_attributes['page_url']
      
      # Now that we know we have a URL, include other information if available
      if conversation.custom_attributes['page_title'].present?
        payload[:visitor_page][:page_title] = conversation.custom_attributes['page_title']
        payload[:page_title] = conversation.custom_attributes['page_title']
      end
      
      if conversation.custom_attributes['referer_url'].present?
        payload[:visitor_page][:referer_url] = conversation.custom_attributes['referer_url']
        payload[:referer_url] = conversation.custom_attributes['referer_url']
      end
    end
    
    payload
  end
end
