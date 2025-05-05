class WebhookListener < BaseListener
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    
    add_page_info_to_payload(payload, conversation) if conversation.present?
    
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
    
    add_page_info_to_payload(payload, conversation) if conversation.present?
    
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_updated(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    
    add_page_info_to_payload(payload, conversation) if conversation.present?
    
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s)
    
    add_page_info_to_payload(payload, conversation) if conversation.present?
    
    deliver_webhook_payloads(payload, inbox)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    # Create the base payload
    payload = message.webhook_data.merge(event: __method__.to_s)
    
    # Directly add page information to the payload
    payload[:visitor_page] = {}
    
    # From message content_attributes if available
    if message.content_attributes.present? && message.content_attributes['page_info'].present?
      page_info = message.content_attributes['page_info']
      payload[:visitor_page][:page_url] = page_info['page_url']
      payload[:visitor_page][:page_title] = page_info['page_title']
      payload[:visitor_page][:referer_url] = page_info['referer_url']
    end
    
    # From conversation if available
    conversation = message.conversation
    if conversation&.additional_attributes.present?
      payload[:visitor_page][:page_url] ||= conversation.additional_attributes['page_url']
      payload[:visitor_page][:page_title] ||= conversation.additional_attributes['page_title']
      payload[:visitor_page][:referer_url] ||= conversation.additional_attributes['referer']
      payload[:visitor_page][:browser] = conversation.additional_attributes['browser']
      payload[:visitor_page][:browser_language] = conversation.additional_attributes['browser_language']
    end

    # Always include current window location information if available
    if message.content.present? && message.content.include?('window.location')
      begin
        window_info = JSON.parse(message.content)
        payload[:visitor_page][:page_url] ||= window_info['window_location']
      rescue
        # In case parsing fails, ignore and continue
      end
    end
    
    deliver_webhook_payloads(payload, inbox)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    # Create the base payload
    payload = message.webhook_data.merge(event: __method__.to_s)
    
    # Directly add page information to the payload
    payload[:visitor_page] = {}
    
    # From message content_attributes if available
    if message.content_attributes.present? && message.content_attributes['page_info'].present?
      page_info = message.content_attributes['page_info']
      if page_info.is_a?(String)
        begin
          parsed_info = JSON.parse(page_info.gsub('=>', ':'))
          page_info = parsed_info
        rescue
          # If parsing fails, use as is
        end
      end
      
      payload[:visitor_page][:page_url] = page_info['page_url']
      payload[:visitor_page][:page_title] = page_info['page_title']
      payload[:visitor_page][:referer_url] = page_info['referer_url']
    end
    
    # From conversation if available
    conversation = message.conversation
    if conversation&.additional_attributes.present?
      payload[:visitor_page][:page_url] ||= conversation.additional_attributes['page_url']
      payload[:visitor_page][:page_title] ||= conversation.additional_attributes['page_title']
      payload[:visitor_page][:referer_url] ||= conversation.additional_attributes['referer']
      payload[:visitor_page][:browser] = conversation.additional_attributes['browser']
      payload[:visitor_page][:browser_language] = conversation.additional_attributes['browser_language']
    end

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
      payload[:visitor_page] = {
        referer_url: event_info[:referer],
        page_url: event_info[:page_url],
        page_title: event_info[:page_title]
      }
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
    
    # Create the enriched payload
    enriched_payload = payload.dup
    
    # Ensure we always add the Chatwoot instance information
    enriched_payload[:chatwoot_instance] = {
      frontend_url: frontend_url,
      host: host
    }
    
    # Ensure visitor page info is available at the root level for all events
    if payload[:visitor_page].present?
      # Copy important fields to root level for direct access
      enriched_payload[:page_url] = payload[:visitor_page][:page_url]
      enriched_payload[:page_title] = payload[:visitor_page][:page_title]
      enriched_payload[:referer_url] = payload[:visitor_page][:referer_url]
    end
    
    # Deliver the webhooks with the enriched payload
    deliver_account_webhooks(enriched_payload, inbox.account)
    deliver_api_inbox_webhooks(enriched_payload, inbox)
  end

  def add_page_info_to_payload(payload, conversation, message = nil)
    visitor_page = {}
    
    # Try to get page info from conversation's additional_attributes
    if conversation&.additional_attributes.present?
      visitor_page = {
        referer_url: conversation.additional_attributes['referer'],
        page_url: conversation.additional_attributes['page_url'],
        page_title: conversation.additional_attributes['page_title'],
        browser: conversation.additional_attributes['browser'],
        browser_language: conversation.additional_attributes['browser_language'],
        initiated_at: conversation.additional_attributes['initiated_at']
      }
    end
    
    # Try to get page info from message's content_attributes (this is the new approach)
    if message.present? && message.content_attributes.present? && message.content_attributes['page_info'].present?
      page_info = message.content_attributes['page_info']
      visitor_page[:referer_url] ||= page_info['referer_url']
      visitor_page[:page_url] ||= page_info['page_url']
      visitor_page[:page_title] ||= page_info['page_title']
    end
    
    # Only add visitor_page if it contains any data
    payload[:visitor_page] = visitor_page if visitor_page.values.any?(&:present?)
  end
end
