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
      
      payload[:visitor_page][:page_url] = page_info['page_url']
      payload[:visitor_page][:page_title] = page_info['page_title']
      payload[:visitor_page][:referer_url] = page_info['referer_url']
    end
    
    # From conversation if available
    conversation = message.conversation
    if conversation&.custom_attributes.present?
      payload[:visitor_page][:page_url] ||= conversation.custom_attributes['page_url']
      payload[:visitor_page][:page_title] ||= conversation.custom_attributes['page_title']
      payload[:visitor_page][:referer_url] ||= conversation.custom_attributes['referer_url']
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
      
      payload[:visitor_page][:page_url] = page_info['page_url']
      payload[:visitor_page][:page_title] = page_info['page_title']
      payload[:visitor_page][:referer_url] = page_info['referer_url']
    end
    
    # From conversation if available
    conversation = message.conversation
    if conversation&.custom_attributes.present?
      payload[:visitor_page][:page_url] ||= conversation.custom_attributes['page_url']
      payload[:visitor_page][:page_title] ||= conversation.custom_attributes['page_title']
      payload[:visitor_page][:referer_url] ||= conversation.custom_attributes['referer_url']
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
      # Make sure URLs don't have trailing semicolons
      referer = event_info[:referer]&.gsub(/;$/, '')
      page_url = event_info[:page_url]&.gsub(/;$/, '')
      
      payload[:visitor_page] = {
        referer_url: referer,
        page_url: page_url,
        page_title: event_info[:page_title]
      }
      
      # Add directly to root level as well
      payload[:referer_url] = referer
      payload[:page_url] = page_url
      payload[:page_title] = event_info[:page_title]
    end
    
    deliver_webhook_payloads(payload, inbox)
  end

  def contact_created(event)
    contact, account = extract_contact_and_account(event)
    payload = contact.webhook_data.merge(event: __method__.to_s)
    
    # Check if there are any recent conversations involving this contact
    recent_conversation = contact.conversations.order(created_at: :desc).first
    add_page_info_to_payload(payload, recent_conversation) if recent_conversation.present?
    
    deliver_account_webhooks(payload, account)
  end

  def contact_updated(event)
    contact, account = extract_contact_and_account(event)
    changed_attributes = extract_changed_attributes(event)
    return if changed_attributes.blank?

    payload = contact.webhook_data.merge(event: __method__.to_s, changed_attributes: changed_attributes)
    
    # Check if there are any recent conversations involving this contact
    recent_conversation = contact.conversations.order(created_at: :desc).first
    add_page_info_to_payload(payload, recent_conversation) if recent_conversation.present?
    
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
    
    # Ensure we always add the Chatwoot instance information
    enriched_payload[:chatwoot_instance] = {
      frontend_url: frontend_url,
      host: host
    }
    
    # Ensure visitor page info is available at the root level for all events
    if enriched_payload[:visitor_page].present?
      # Copy important fields to root level for direct access
      enriched_payload[:page_url] ||= enriched_payload[:visitor_page][:page_url]
      enriched_payload[:page_title] ||= enriched_payload[:visitor_page][:page_title]
      enriched_payload[:referer_url] ||= enriched_payload[:visitor_page][:referer_url]
      
      # Add each key-value pair from visitor_page to the root for direct access
      enriched_payload[:visitor_page].each do |key, value|
        enriched_payload[key] ||= value if value.present?
      end
    end
    
    enriched_payload
  end

  def deliver_api_inbox_webhooks(payload, inbox)
    return unless inbox.channel_type == 'Channel::Api'
    return if inbox.channel.webhook_url.blank?

    WebhookJob.perform_later(inbox.channel.webhook_url, payload, :api_inbox_webhook)
  end

  def deliver_webhook_payloads(payload, inbox)
    # Ensure page info is available for every webhook by checking the conversation if needed
    if payload[:conversation].present? && payload[:visitor_page].blank?
      conversation_id = payload[:conversation][:id]
      conversation = Conversation.find_by(id: conversation_id)
      
      if conversation&.custom_attributes.present? && conversation.custom_attributes['page_url'].present?
        # Add visitor page info from conversation custom attributes
        payload[:visitor_page] ||= {}
        payload[:visitor_page][:page_url] = conversation.custom_attributes['page_url']
        payload[:visitor_page][:page_title] = conversation.custom_attributes['page_title'] if conversation.custom_attributes['page_title'].present?
        payload[:visitor_page][:referer_url] = conversation.custom_attributes['referer_url'] if conversation.custom_attributes['referer_url'].present?
      end
      
      # Try to get recent messages to extract page info
      recent_message = conversation.messages.where.not(message_type: :activity).order(created_at: :desc).first
      if recent_message&.content_attributes.present? && recent_message.content_attributes['page_info'].present?
        page_info = recent_message.content_attributes['page_info']
        
        if page_info.is_a?(String)
          begin
            # Try to parse it if it's a string - handle both JSON and Ruby hash notations
            page_info = if page_info.include?('=>')
                          eval(page_info)
                        else
                          JSON.parse(page_info)
                        end
          rescue => e
            Rails.logger.error "Error parsing page_info in deliver_webhook_payloads: #{e.message}"
          end
        end
        
        payload[:visitor_page] ||= {}
        payload[:visitor_page][:page_url] ||= page_info['page_url'] if page_info['page_url'].present?
        payload[:visitor_page][:page_title] ||= page_info['page_title'] if page_info['page_title'].present?
        payload[:visitor_page][:referer_url] ||= page_info['referer_url'] if page_info['referer_url'].present?
      end
    end
    
    # Create enriched payload with consistent structure
    enriched_payload = enhance_webhook_payload(payload)
    
    # Deliver the webhooks with the enriched payload
    deliver_account_webhooks(enriched_payload, inbox.account)
    deliver_api_inbox_webhooks(enriched_payload, inbox)
  end

  def add_page_info_to_payload(payload, conversation, message = nil)
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
        visitor_page = { page_url: page_info['page_url'] }
        
        # Add other info if available
        visitor_page[:page_title] = page_info['page_title'] if page_info['page_title'].present?
        visitor_page[:referer_url] = page_info['referer_url'] if page_info['referer_url'].present?
        
        # Add to payload
        payload[:visitor_page] = visitor_page
        payload[:page_url] = visitor_page[:page_url]
        payload[:page_title] = visitor_page[:page_title] if visitor_page[:page_title].present?
        payload[:referer_url] = visitor_page[:referer_url] if visitor_page[:referer_url].present?
        
        # We found page URL in message, so we're done
        return
      end
    end
    
    # If we didn't find page URL in message, check conversation custom_attributes
    if conversation&.custom_attributes.present?
      if conversation.custom_attributes['page_url'].present?
        visitor_page = { page_url: conversation.custom_attributes['page_url'] }
        
        # Add other info if available
        visitor_page[:page_title] = conversation.custom_attributes['page_title'] if conversation.custom_attributes['page_title'].present?
        visitor_page[:referer_url] = conversation.custom_attributes['referer_url'] if conversation.custom_attributes['referer_url'].present?
        
        # Add to payload
        payload[:visitor_page] = visitor_page
        payload[:page_url] = visitor_page[:page_url]
        payload[:page_title] = visitor_page[:page_title] if visitor_page[:page_title].present?
        payload[:referer_url] = visitor_page[:referer_url] if visitor_page[:referer_url].present?
      end
    end
  end
end
