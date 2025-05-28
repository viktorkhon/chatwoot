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
    
    Rails.logger.info "[CONVERSATION DEBUG] conversation_created webhook triggered - Conversation ID: #{conversation.id}, Contact: #{conversation.contact.id}, Inbox: #{inbox.id}, Source: #{conversation.contact_inbox.source_id}"
    
    payload = conversation.webhook_data.merge(event: __method__.to_s)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, conversation)
    
    Rails.logger.info "[CONVERSATION DEBUG] Sending conversation_created webhook to external systems - Conversation: #{conversation.id}, Event: conversation_created"
    
    deliver_webhook_payloads(payload, inbox)
    
    Rails.logger.info "[CONVERSATION DEBUG] conversation_created webhook delivery completed - Conversation: #{conversation.id}"
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

    Rails.logger.info "[CONVERSATION DEBUG] message_updated webhook triggered - Message ID: #{message.id}, Conversation ID: #{message.conversation.id}, Contact: #{message.conversation.contact.id}, Inbox: #{inbox.id}"

    # Create the base payload
    payload = message.webhook_data.merge(event: __method__.to_s)
    
    # Ensure custom_attributes exists
    payload[:custom_attributes] ||= {}
    
    # Add page information to custom_attributes
    add_page_info_to_custom_attributes(payload, message.conversation, message)
    
    # Log the conversation IDs being sent to n8n
    Rails.logger.info "[CONVERSATION DEBUG] Webhook payload conversation IDs - Actual ID: #{message.conversation.id}, Display ID: #{message.conversation.display_id}"
    Rails.logger.info "[CONVERSATION DEBUG] Payload structure - conversation.id: #{payload[:conversation][:id]}, top-level id: #{payload[:id]}"
    Rails.logger.info "[CONVERSATION DEBUG] n8n should use conversation.id (#{payload[:conversation][:id]}) for API calls, NOT the top-level id (#{payload[:id]})"
    
    # Enhanced warning about payload structure
    Rails.logger.warn "[CONVERSATION DEBUG] CRITICAL PAYLOAD ANALYSIS:"
    Rails.logger.warn "[CONVERSATION DEBUG] Top-level 'id': #{payload[:id]} (THIS IS MESSAGE ID - DO NOT USE FOR CONVERSATION CREATION!)"
    Rails.logger.warn "[CONVERSATION DEBUG] conversation.id: #{payload[:conversation][:id]} (THIS IS DISPLAY_ID - USE THIS FOR /conversations/{id}/messages)"
    Rails.logger.warn "[CONVERSATION DEBUG] If n8n calls /conversations with message ID #{payload[:id]}, it will create DUPLICATE conversations!"
    Rails.logger.warn "[CONVERSATION DEBUG] CORRECT n8n endpoint: /conversations/#{payload[:conversation][:id]}/messages"
    Rails.logger.warn "[CONVERSATION DEBUG] WRONG n8n endpoint: /conversations (using any ID from this payload)"
    
    Rails.logger.info "[CONVERSATION DEBUG] Sending message_updated webhook to external systems - Conversation: #{message.conversation.id}, Message: #{message.id}, Event: message_updated"
    
    deliver_webhook_payloads(payload, inbox)
    
    Rails.logger.info "[CONVERSATION DEBUG] message_updated webhook delivery completed - Conversation: #{message.conversation.id}, Message: #{message.id}"
  end

  def webwidget_triggered(event)
    contact_inbox = event.data[:contact_inbox]
    inbox = contact_inbox.inbox

    # Prevent duplicate webwidget_triggered webhooks during the same session
    # Check if we've already sent this webhook for this contact_inbox recently
    session_key = "webwidget_triggered:#{contact_inbox.source_id}:#{inbox.account_id}"
    
    begin
      # Check if webhook was already sent in the last 30 minutes (session duration)
      if $alfred.with { |conn| conn.get(session_key) }
        return
      end
      
      # Mark this session as having sent the webhook (expires in 30 minutes)
      $alfred.with do |conn|
        conn.set(session_key, Time.current.to_i)
        conn.expire(session_key, 30.minutes.to_i)
      end
    rescue => e
      Rails.logger.error "[WebhookListener] Redis error in webwidget_triggered: #{e.message}"
      # Continue with webhook if Redis fails
    end

    event_info = event.data[:event_info] || {}
    page_url_from_event = event_info[:page_url]
    referer_url_from_event = event_info[:referer]
    actual_page_url = page_url_from_event
    browser_details = event_info[:browser] || {}

    # Prepare the data from ContactInbox that will be merged at the top level
    contact_inbox_payload_data = contact_inbox.webhook_data

    payload = {
      # id: SecureRandom.uuid, # This will be overwritten by contact_inbox_payload_data[:id]
      event: __method__.to_s,
      # 'account' key will come from contact_inbox_payload_data after merge
      website: { 
        url: actual_page_url
      },
      # 'visitor' key is removed as its contents will be merged.
      browser: {
        browser_name: browser_details['browser_name'],
        browser_version: browser_details['browser_version'],
        platform_name: browser_details['platform_name'],
        platform_version: browser_details['platform_version']
      }.compact,
      triggered_at: Time.now,
      custom_attributes: {} # Initialize event-specific custom_attributes
    }

    payload[:custom_attributes]['page_url'] = actual_page_url if actual_page_url.present?
    payload[:custom_attributes]['referer_url'] = referer_url_from_event if referer_url_from_event.present?
    # Note: page_title is not directly available from event.data for webwidget_triggered.

    # Merge contact_inbox_payload_data into the main payload.
    # This will add keys like 'id', 'contact', 'inbox', 'account', 'source_id' to the top level,
    # overwriting 'id' and providing 'account' from contact_inbox context.
    payload.merge!(contact_inbox_payload_data)
    
    # Enhanced logging for webwidget_triggered payload structure
    Rails.logger.info "[CONVERSATION DEBUG] webwidget_triggered webhook triggered - ContactInbox ID: #{contact_inbox.id}, Source ID: #{contact_inbox.source_id}"
    Rails.logger.info "[CONVERSATION DEBUG] WEBWIDGET PAYLOAD ANALYSIS:"
    Rails.logger.info "[CONVERSATION DEBUG] Top-level 'id': #{payload[:id]} (THIS IS CONTACT_INBOX ID - SAFE TO USE FOR CONVERSATION CREATION)"
    Rails.logger.info "[CONVERSATION DEBUG] source_id: #{payload[:source_id]} (THIS IS CONTACT SOURCE ID)"
    Rails.logger.info "[CONVERSATION DEBUG] current_conversation: #{payload[:current_conversation]&.dig(:id) || 'nil'} (Existing conversation if any)"
    Rails.logger.info "[CONVERSATION DEBUG] For webwidget_triggered, n8n SHOULD call /conversations to create new conversation"
    Rails.logger.info "[CONVERSATION DEBUG] This is the CORRECT use case for conversation creation endpoint"
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

  def shopify_name_updated(event)
    account = event.data[:account]
    shopify_name_change = event.data[:shopify_name_change]
    
    # Only proceed if we have valid data
    return if account.blank? || shopify_name_change.blank?
    
    # Get previous and current values
    previous_value = shopify_name_change[0]
    current_value = shopify_name_change[1]
    
    # Create the payload
    payload = {
      event: __method__.to_s,
      account: account.webhook_data,
      shopify_name: {
        previous_value: previous_value,
        current_value: current_value
      }
    }
    
    # Deliver to subscribed webhooks
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
