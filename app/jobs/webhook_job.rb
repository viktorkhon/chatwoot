class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook)
    # Log the original payload for debugging
    Rails.logger.debug "WebhookJob - Original payload: #{payload.to_json}"
    
    # Ensure page_info is always included in the payload
    enriched_payload = ensure_page_info_in_payload(payload)
    
    # Log the enriched payload for debugging
    Rails.logger.debug "WebhookJob - Enriched payload: #{enriched_payload.to_json}"
    
    Webhooks::Trigger.execute(url, enriched_payload, webhook_type)
  end

  private

  def ensure_page_info_in_payload(payload)
    # Return original payload if already has page info
    if payload[:page_url].present? || payload[:referer_url].present? || payload[:visitor_page].present?
      Rails.logger.debug "WebhookJob - Payload already has page info"
      return payload
    end
    
    # Create a copy to modify
    enriched_payload = payload.dup
    
    # Check conversation in various places to ensure we extract page info
    conversation = nil
    conversation_id = nil
    
    # Option 1: Direct conversation_id
    if enriched_payload[:conversation_id].present?
      conversation_id = enriched_payload[:conversation_id]
      conversation = Conversation.find_by(id: conversation_id)
      Rails.logger.debug "WebhookJob - Found conversation from conversation_id: #{conversation_id}" if conversation
      enrich_from_conversation(enriched_payload, conversation) if conversation
    
    # Option 2: Conversation object with ID
    elsif enriched_payload[:conversation].present? && enriched_payload[:conversation][:id].present?
      conversation_id = enriched_payload[:conversation][:id]
      conversation = Conversation.find_by(id: conversation_id)
      Rails.logger.debug "WebhookJob - Found conversation from conversation hash: #{conversation_id}" if conversation
      enrich_from_conversation(enriched_payload, conversation) if conversation
      
    # Option 3: Look for message with conversation
    elsif enriched_payload[:id].present? && enriched_payload[:message_type].present?
      message = Message.find_by(id: enriched_payload[:id])
      if message&.conversation.present?
        conversation = message.conversation
        conversation_id = conversation.id
        Rails.logger.debug "WebhookJob - Found conversation from message: #{conversation_id}"
        enrich_from_conversation(enriched_payload, conversation)
      end
    end
    
    # If we still don't have page info, try to find it from recent conversations
    if (enriched_payload[:page_url].blank? && enriched_payload[:visitor_page].blank?) && 
        enriched_payload[:sender].present? && enriched_payload[:sender][:id].present? && 
        enriched_payload[:sender][:type] == "agent_bot"
      
      if conversation_id.present?
        Rails.logger.debug "WebhookJob - Looking for recent conversations for bot message conversation: #{conversation_id}"
        # Try to get more recent messages from this conversation to find page info
        recent_message = Message.where(conversation_id: conversation_id)
                               .where.not(message_type: :activity)
                               .where.not(id: enriched_payload[:id])
                               .order(created_at: :desc)
                               .first
                               
        if recent_message&.content_attributes.present? && recent_message.content_attributes['page_info'].present?
          Rails.logger.debug "WebhookJob - Found page info in recent message #{recent_message.id}"
          add_page_info_from_message(enriched_payload, recent_message)
        end
      end
    end
    
    # Add empty visitor_page if it's still missing to prevent key errors
    enriched_payload[:visitor_page] ||= {}
    
    enriched_payload
  end
  
  def add_page_info_from_message(payload, message)
    page_info = message.content_attributes['page_info']
    if page_info.is_a?(String)
      begin
        # Try to parse it if it's a string - handle both JSON and Ruby hash notations
        page_info = if page_info.include?('=>')
                      eval(page_info)
                    else
                      JSON.parse(page_info)
                    end
      rescue => e
        Rails.logger.error "Error parsing page_info: #{e.message}"
      end
    end
    
    if page_info.is_a?(Hash) && page_info['page_url'].present?
      payload[:visitor_page] ||= {}
      payload[:visitor_page][:page_url] = page_info['page_url']
      payload[:page_url] = page_info['page_url']
      
      if page_info['page_title'].present?
        payload[:visitor_page][:page_title] = page_info['page_title']
        payload[:page_title] = page_info['page_title']
      end
      
      if page_info['referer_url'].present?
        payload[:visitor_page][:referer_url] = page_info['referer_url']
        payload[:referer_url] = page_info['referer_url']
      end
    end
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
      
      Rails.logger.debug "WebhookJob - Added page info from conversation: #{payload[:page_url]}"
    else
      Rails.logger.debug "WebhookJob - Conversation #{conversation.id} has no page URL in custom_attributes"
    end
    
    payload
  end
end
