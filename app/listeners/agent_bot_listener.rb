class AgentBotListener < BaseListener
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    return unless connected_agent_bot_exist?(inbox)

    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    process_webhook_bot_event(inbox.agent_bot, payload)
  end

  def conversation_opened(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    return unless connected_agent_bot_exist?(inbox)

    event_name = __method__.to_s
    payload = conversation.webhook_data.merge(event: event_name)
    process_webhook_bot_event(inbox.agent_bot, payload)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless connected_agent_bot_exist?(inbox)
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    process_message_event(method_name, inbox.agent_bot, message, event)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox
    return unless connected_agent_bot_exist?(inbox)
    return unless message.webhook_sendable?

    method_name = __method__.to_s
    process_message_event(method_name, inbox.agent_bot, message, event)
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox
    return unless connected_agent_bot_exist?(inbox)

    # Extract event info with page URL data
    event_info = event.data[:event_info]
    
    # Store page URL information in Redis for future use
    if event_info.present? && event_info[:page_url].present?
      # Create a Redis key using the contact_inbox source_id
      redis_key = "contact_inbox:#{contact_inbox.source_id}:page_info"
      page_info = {
        page_url: event_info[:page_url],
        page_title: event_info[:page_title],
        referer_url: event_info[:referer]
      }
      
      # Store in Redis with a 30 minute expiration
      $alfred.with do |conn|
        conn.set(redis_key, page_info.to_json)
        conn.expire(redis_key, 30.minutes.to_i)
      end
      
      Rails.logger.info "AgentBotListener - Stored page info in Redis for contact_inbox: #{contact_inbox.source_id}"
    end

    event_name = __method__.to_s
    payload = contact_inbox.webhook_data.merge(event: event_name)
    payload[:event_info] = event_info
    process_webhook_bot_event(inbox.agent_bot, payload)
  end

  private

  def connected_agent_bot_exist?(inbox)
    return if inbox.agent_bot_inbox.blank?
    return unless inbox.agent_bot_inbox.active?

    true
  end

  def process_message_event(method_name, agent_bot, message, _event)
    # Only webhook bots are supported
    payload = message.webhook_data.merge(event: method_name)
        
    # Debug logging to understand the payload structure
    Rails.logger.debug "AgentBotListener - webhook_data for message #{message.id}: #{payload.to_json}"
    
    # Check if page info is missing and try to add it from conversation
    if (payload[:page_url].blank? || payload[:visitor_page].blank?) && message.conversation.present?
      conversation = message.conversation
      Rails.logger.debug "AgentBotListener - conversation custom_attributes: #{conversation.custom_attributes}"
      
      if conversation.custom_attributes.present? && conversation.custom_attributes['page_url'].present?
        # Add page URL information directly to the payload
        payload[:page_url] = conversation.custom_attributes['page_url']
        payload[:page_title] = conversation.custom_attributes['page_title']
        payload[:referer_url] = conversation.custom_attributes['referer_url']
        
        # Also add to visitor_page object
        payload[:visitor_page] ||= {}
        payload[:visitor_page][:page_url] = conversation.custom_attributes['page_url']
        payload[:visitor_page][:page_title] = conversation.custom_attributes['page_title'] if conversation.custom_attributes['page_title'].present?
        payload[:visitor_page][:referer_url] = conversation.custom_attributes['referer_url'] if conversation.custom_attributes['referer_url'].present?
      end
    end
    
    process_webhook_bot_event(agent_bot, payload)
  end

  def process_webhook_bot_event(agent_bot, payload)
    return if agent_bot.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload)
  end
end
