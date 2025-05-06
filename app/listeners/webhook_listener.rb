class WebhookListener < BaseListener
  def conversation_status_changed(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, conversation)
    
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
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, conversation)
    
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_updated(event)
    conversation = extract_conversation_and_account(event)[0]
    changed_attributes = extract_changed_attributes(event)
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, conversation)
    
    deliver_webhook_payloads(payload, inbox)
  end

  def conversation_created(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    payload = conversation.webhook_data.merge(event: __method__.to_s)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, conversation)
    
    deliver_webhook_payloads(payload, inbox)
  end

  def message_created(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    # Create the base payload
    payload = message.webhook_data.merge(event: __method__.to_s)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, message.conversation, message)
    
    deliver_webhook_payloads(payload, inbox)
  end

  def message_updated(event)
    message = extract_message_and_account(event)[0]
    inbox = message.inbox

    return unless message.webhook_sendable?

    # Create the base payload
    payload = message.webhook_data.merge(event: __method__.to_s)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, message.conversation, message)
    
    deliver_webhook_payloads(payload, inbox)
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox

    # Extract event info with page URL
    event_info = event.data[:event_info] || {}
    
    payload = contact_inbox.webhook_data.merge(event: __method__.to_s)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page URL to custom_attributes for easier access in webhooks
    if event_info.present?
      # Make sure URLs don't have trailing semicolons
      referer = event_info[:referer]&.gsub(/;$/, '')
      page_url = event_info[:page_url]&.gsub(/;$/, '')
      
      # Add to custom_attributes
      payload[:custom_attributes]['page_url'] = page_url if page_url.present?
      payload[:custom_attributes]['page_title'] = event_info[:page_title] if event_info[:page_title].present?
      payload[:custom_attributes]['referer_url'] = referer if referer.present?
    end
    
    # Keep event_info in the payload for backwards compatibility
    # but remove any URL data from it
    if event_info.present?
      event_info = event_info.except(:page_url, :page_title, :referer)
      payload[:event_info] = event_info unless event_info.empty?
    end
    
    deliver_webhook_payloads(payload, inbox)
  end

  def contact_created(event)
    contact, account = extract_contact_and_account(event)
    payload = contact.webhook_data.merge(event: __method__.to_s)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Check if there are any recent conversations involving this contact
    recent_conversation = contact.conversations.order(created_at: :desc).first
    add_page_info_to_custom_attributes(payload, recent_conversation) if recent_conversation.present?
    
    deliver_account_webhooks(payload, account)
  end

  def contact_updated(event)
    contact, account = extract_contact_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    payload = contact.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Check if there are any recent conversations involving this contact
    recent_conversation = contact.conversations.order(created_at: :desc).first
    add_page_info_to_custom_attributes(payload, recent_conversation) if recent_conversation.present?
    
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
    # Create an enriched payload with consistent structure
    enriched_payload = enhance_webhook_payload(payload)
    
    # Send the webhook to all subscribed endpoints
    account.webhooks.account_type.each do |webhook|
      next unless webhook.subscriptions.include?(payload[:event])

      WebhookJob.perform_later(webhook.url, enriched_payload)
    end
  end

  # Helper method to create a consistent enriched payload structure
  def enhance_webhook_payload(payload)
    # Add Chatwoot frontend URL to the payload
    frontend_url = ENV.fetch('FRONTEND_URL', '')
    host = begin
      URI.parse(frontend_url).host
    rescue
      nil
    end
    
    # Create the enriched payload
    enriched_payload = payload.dup
    
    # Ensure custom_attributes exists
    enriched_payload[:custom_attributes] ||= {}
    
    # Move chatwoot_instance values into custom_attributes
    enriched_payload[:custom_attributes]['frontend_url'] = frontend_url if frontend_url.present?
    enriched_payload[:custom_attributes]['host'] = host if host.present?
    
    # Remove duplicate URL fields if they exist
    enriched_payload.delete(:visitor_page)
    enriched_payload.delete(:page_url)
    enriched_payload.delete(:page_title)
    enriched_payload.delete(:referer_url)
    enriched_payload.delete(:chatwoot_instance)
    
    enriched_payload
  end

  def deliver_api_inbox_webhooks(payload, inbox)
    return unless inbox.channel_type == 'Channel::Api'
    return if inbox.channel.webhook_url.blank?

    WebhookJob.perform_later(inbox.channel.webhook_url, payload, :api_inbox_webhook)
  end

  def deliver_webhook_payloads(payload, inbox)
    # Create enriched payload with consistent structure
    enriched_payload = enhance_webhook_payload(payload)
    
    # Deliver the webhooks with the enriched payload
    deliver_account_webhooks(enriched_payload, inbox.account)
    deliver_api_inbox_webhooks(enriched_payload, inbox)
  end

  def add_page_info_to_custom_attributes(payload, conversation, message = nil)
    # Check for page URL from message first (most recent)
    if message.present? && message.content_attributes.present? && message.content_attributes['page_info'].present?
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
          # Keep as is if parsing fails
        end
      end
      
      # If we found a page URL in the message, use it
      if page_info['page_url'].present?
        payload[:custom_attributes]['page_url'] = page_info['page_url']
        payload[:custom_attributes]['page_title'] = page_info['page_title'] if page_info['page_title'].present?
        payload[:custom_attributes]['referer_url'] = page_info['referer_url'] if page_info['referer_url'].present?
        return
      end
    end
    
    # If we didn't find page URL in message, check conversation custom_attributes
    if conversation&.custom_attributes.present?
      if conversation.custom_attributes['page_url'].present?
        payload[:custom_attributes]['page_url'] = conversation.custom_attributes['page_url']
        payload[:custom_attributes]['page_title'] = conversation.custom_attributes['page_title'] if conversation.custom_attributes['page_title'].present?
        payload[:custom_attributes]['referer_url'] = conversation.custom_attributes['referer_url'] if conversation.custom_attributes['referer_url'].present?
      end
    end
  end
end
