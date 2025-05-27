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

    # Prevent duplicate webwidget_triggered events during the same session
    # Check if we've already processed this event for this contact_inbox recently
    session_key = "webwidget_triggered_bot:#{contact_inbox.source_id}:#{inbox.account_id}"
    
    begin
      # Check if event was already processed in the last 30 minutes (session duration)
      if $alfred.with { |conn| conn.get(session_key) }
        Rails.logger.info "[AgentBotListener] Skipping duplicate webwidget_triggered event for contact_inbox: #{contact_inbox.source_id}"
        return
      end
      
      # Mark this session as having processed the event (expires in 30 minutes)
      $alfred.with do |conn|
        conn.set(session_key, Time.current.to_i)
        conn.expire(session_key, 30.minutes.to_i)
      end
    rescue => e
      Rails.logger.error "[AgentBotListener] Redis error in webwidget_triggered: #{e.message}"
      # Continue with processing if Redis fails
    end

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
    end

    event_name = __method__.to_s
    payload = contact_inbox.webhook_data.merge(event: event_name)
    payload[:event_info] = event_info
    
    Rails.logger.info "[AgentBotListener] Processing webwidget_triggered event for contact_inbox: #{contact_inbox.source_id}"
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
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Copy page URL info from conversation custom_attributes if available
    if message.conversation.present? && message.conversation.custom_attributes.present?
      conversation = message.conversation
      
      if conversation.custom_attributes['page_url'].present?
        # Only add to custom_attributes, not to root or visitor_page
        payload[:custom_attributes]['page_url'] = conversation.custom_attributes['page_url']
        payload[:custom_attributes]['page_title'] = conversation.custom_attributes['page_title'] if conversation.custom_attributes['page_title'].present?
        payload[:custom_attributes]['referer_url'] = conversation.custom_attributes['referer_url'] if conversation.custom_attributes['referer_url'].present?
      end
    end
    
    # Remove any duplicate data formats we might have added previously
    payload.delete(:visitor_page)
    payload.delete(:page_url)
    payload.delete(:page_title)
    payload.delete(:referer_url)
    
    process_webhook_bot_event(agent_bot, payload)
  end

  def process_webhook_bot_event(agent_bot, payload)
    return if agent_bot.outgoing_url.blank?

    AgentBots::WebhookJob.perform_later(agent_bot.outgoing_url, payload)
  end
end
