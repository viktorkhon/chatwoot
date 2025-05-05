class WebhookListener < BaseListener
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(
      event: __method__.to_s,
      conversation_id: conversation.id,
      account_id: conversation.account_id
    )
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_updated(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload, inbox)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    payload = message.webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload, inbox)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    payload = message.webhook_data.merge(event: __method__.to_s)
    deliver_webhook_payloads(payload, inbox)
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox

    # Extract event info with page URL
    event_info = event.data[:event_info] || {}
    
    payload = contact_inbox.webhook_data.merge(event: __method__.to_s)
    payload[:event_info] = event_info
    
    # Add page URL directly to the payload for easier access in webhooks
    if event_info.present?
      payload[:page_url] = event_info[:page_url] 
      payload[:page_title] = event_info[:page_title]
      payload[:referer] = event_info[:referer]
    end
    
    deliver_webhook_payloads(payload, inbox)
  end

  def contact_created(event)
    contact, account = extract_contact_and_account(event)
    payload = contact.webhook_data.merge(event: __method__.to_s)
    deliver_account_webhooks(payload, account)
  end

  def contact_updated(event)
    contact, account = extract_contact_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    payload = contact.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_account_webhooks(payload, account)
  end

  def inbox_created(event)
    inbox, account = extract_inbox_and_account(event)
    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).push_data
    payload = inbox_webhook_data.merge(event: __method__.to_s)
    deliver_account_webhooks(payload, account)
  end

  def inbox_updated(event)
    inbox, account = extract_inbox_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    inbox_webhook_data = Inbox::EventDataPresenter.new(inbox).push_data
    payload = inbox_webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    deliver_account_webhooks(payload, account)
  end

  private

  def deliver_account_webhooks(payload, account)
    account.webhooks.account_type.each do |webhook|
      next unless webhook.subscriptions.include?(payload[:event])

      WebhookJob.perform_later(webhook.url, payload)
    end
  end

  def deliver_api_inbox_webhooks(payload, inbox)
    return unless inbox.channel_type == 'Channel::Api'
    return if inbox.channel.webhook_url.blank?

    WebhookJob.perform_later(inbox.channel.webhook_url, payload, :api_inbox_webhook)
  end

  def deliver_webhook_payloads(payload, inbox)
    # Add Chatwoot frontend URL to the payload
    frontend_url = ENV.fetch('FRONTEND_URL', '')
    host = begin
      URI.parse(frontend_url).host
    rescue
      nil
    end
    
    # Create enriched payload with Chatwoot instance information
    enriched_payload = payload.dup
    enriched_payload[:chatwoot_instance] = {
      frontend_url: frontend_url,
      host: host
    }
    
    # Add visitor's page information based on event type
    case enriched_payload[:event]
    when 'message_created', 'message_updated'
      # For message events, get the conversation from the message's conversation
      if enriched_payload[:conversation].present?
        conversation_id = enriched_payload[:conversation][:id]
        conversation = Conversation.find_by(id: conversation_id)
        add_page_info_to_payload(enriched_payload, conversation)
      end
    when 'conversation_created', 'conversation_updated', 'conversation_status_changed'
      # For conversation events, get the conversation directly
      conversation_id = enriched_payload[:id]
      conversation = Conversation.find_by(id: conversation_id)
      add_page_info_to_payload(enriched_payload, conversation)
    when 'webwidget_triggered'
      # For widget events, the conversation might not exist yet, so use event_info
      if enriched_payload[:event_info].present?
        enriched_payload[:visitor_page] = {
          referer_url: enriched_payload[:event_info][:referer],
          page_url: enriched_payload[:event_info][:page_url]
        }
      end
    end
    
    deliver_account_webhooks(enriched_payload, inbox.account)
    deliver_api_inbox_webhooks(enriched_payload, inbox)
  end

  def add_page_info_to_payload(payload, conversation)
    if conversation&.additional_attributes.present?
      payload[:visitor_page] = {
        referer_url: conversation.additional_attributes['referer'],
        browser: conversation.additional_attributes['browser'],
        browser_language: conversation.additional_attributes['browser_language'],
        initiated_at: conversation.additional_attributes['initiated_at']
      }
    end
  end
end
