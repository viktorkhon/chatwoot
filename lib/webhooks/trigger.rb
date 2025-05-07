class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze

  def initialize(url, payload, webhook_type)
    @url = url
    @payload = payload
    @webhook_type = webhook_type
  end

  def self.execute(url, payload, webhook_type)
    Rails.logger.debug "Webhooks::Trigger.execute - URL: #{url}, Webhook Type: #{webhook_type}, Payload: #{payload.to_json}"
    
    begin
      # Ensure payload content_type is properly serialized as a string, not a symbol
      if payload[:content_type].present? && payload[:content_type].is_a?(Symbol)
        payload[:content_type] = payload[:content_type].to_s
      end
      
      # Adds additional debug logging for content_type
      if payload[:content_type].present?
        Rails.logger.debug "Webhooks::Trigger.execute - Content Type: #{payload[:content_type]}, Class: #{payload[:content_type].class}"
      end
      
      # Ensure page info is at the root level of the payload
      payload = ensure_page_info_at_root(payload)
      
      response = perform_request(url, payload)
      Rails.logger.debug "Webhooks::Trigger.execute - Response: Status #{response.status}, Body: #{response.body.to_s[0...500]}"
      
      update_message_status(payload, response) if should_update_message_status?(webhook_type)
      
      response
    rescue StandardError => e
      error_class = e.class.name
      error_message = e.message
      error_backtrace = e.backtrace[0..5].join("\n")
      Rails.logger.error "Webhooks::Trigger.execute - Error: #{error_class}: #{error_message}\n#{error_backtrace}"
      
      handle_error(url, e)
      
      nil
    end
  end

  def self.perform_request(url, payload)
    # Get account from payload if conversation is present
    account = nil
    if payload[:conversation].present? && payload[:conversation][:account_id].present?
      account = Account.find_by(id: payload[:conversation][:account_id])
    end

    # Set up headers with vector_database_namespace if available
    headers = { 'Content-Type' => 'application/json' }
    if account&.vector_database_namespace.present?
      headers['X-Vector-Database-Namespace'] = account.vector_database_namespace
    end

    response = HTTParty.post(
      url,
      body: payload.to_json,
      headers: headers,
      timeout: 5
    )

    if response.success?
      response
    else
      Rails.logger.warn "Webhooks::Trigger - Unsuccessful response: #{response.code} #{response.message}"
      raise StandardError, "#{response.code} #{response.message}"
    end
  end

  def self.handle_error(url, error)
    Rails.logger.warn "Invalid webhook URL #{url} : #{error.message}"
  end

  def self.should_update_message_status?(webhook_type)
    %w[message_created message_updated].include?(webhook_type)
  end

  def self.update_message_status(payload, response)
    message = Message.find_by(id: payload[:id])
    return if message.blank?

    response = evaluate_response(response)
    message.external_status = response&.dig(:status) || ''
    message.save!
  end

  def self.evaluate_response(response)
    response&.parsed_response.presence || { status: 'delivered' }
  end

  def self.ensure_page_info_at_root(payload)
    # Clone the payload to modify it
    enriched_payload = payload.dup
    
    # Add debug logging
    Rails.logger.debug "Webhooks::Trigger - Ensuring page info for payload: #{enriched_payload[:page_url].present? ? 'Has page_url' : 'No page_url'}, visitor_page: #{enriched_payload[:visitor_page].present? ? (enriched_payload[:visitor_page].empty? ? 'Empty' : 'Has content') : 'Missing'}"
    
    # Check if visitor_page is empty and remove it to prevent empty objects in the final payload
    if enriched_payload[:visitor_page].is_a?(Hash) && enriched_payload[:visitor_page].empty?
      Rails.logger.debug "Webhooks::Trigger - Removing empty visitor_page object"
      enriched_payload.delete(:visitor_page)
    end
    
    # Check if page URL exists in visitor_page
    if payload[:visitor_page].present? && !payload[:visitor_page].empty? && 
       payload[:visitor_page][:page_url].present? && enriched_payload[:page_url].blank?
      
      enriched_payload[:page_url] = payload[:visitor_page][:page_url]
      Rails.logger.debug "Webhooks::Trigger - Added page_url from visitor_page: #{enriched_payload[:page_url]}"
      
      # Include other info if available
      if payload[:visitor_page][:page_title].present?
        enriched_payload[:page_title] = payload[:visitor_page][:page_title]
      end
      
      if payload[:visitor_page][:referer_url].present?
        enriched_payload[:referer_url] = payload[:visitor_page][:referer_url]
      end
    end
    
    # Check for page_url in conversation's custom_attributes
    if enriched_payload[:page_url].blank? && payload[:conversation].present? && 
       payload[:conversation][:custom_attributes].present? && 
       payload[:conversation][:custom_attributes].is_a?(Hash) &&
       payload[:conversation][:custom_attributes]['page_url'].present?
       
      # We found a URL in conversation attributes
      enriched_payload[:page_url] = payload[:conversation][:custom_attributes]['page_url']
      Rails.logger.debug "Webhooks::Trigger - Added page_url from conversation custom_attributes: #{enriched_payload[:page_url]}"
      
      # Include other info if available
      attrs = payload[:conversation][:custom_attributes]
      enriched_payload[:page_title] = attrs['page_title'] if attrs['page_title'].present?
      enriched_payload[:referer_url] = attrs['referer_url'] if attrs['referer_url'].present?
    end
    
    # Remove empty objects at the root level
    [:visitor_page].each do |key|
      if enriched_payload[key].is_a?(Hash) && enriched_payload[key].empty?
        enriched_payload.delete(key)
        Rails.logger.debug "Webhooks::Trigger - Removed empty #{key} from payload"
      end
    end
    
    enriched_payload
  end

  def execute
    perform_request
  rescue StandardError => e
    handle_error(e)
    Rails.logger.warn "Exception: Invalid webhook URL #{@url} : #{e.message}"
  end

  private

  def perform_request
    # Ensure payload content_type is properly serialized as a string
    if @payload[:content_type].present? && @payload[:content_type].is_a?(Symbol)
      @payload[:content_type] = @payload[:content_type].to_s
    end
    
    # Get account from payload if conversation is present
    account = nil
    if @payload[:conversation].present? && @payload[:conversation][:account_id].present?
      account = Account.find_by(id: @payload[:conversation][:account_id])
    end

    # Set up headers with vector_database_namespace if available
    headers = { content_type: :json, accept: :json }
    if account&.vector_database_namespace.present?
      headers['X-Vector-Database-Namespace'] = account.vector_database_namespace
    end
    
    RestClient::Request.execute(
      method: :post,
      url: @url,
      payload: @payload.to_json,
      headers: headers,
      timeout: 5
    )
  end

  def handle_error(error)
    return unless should_handle_error?
    return unless message

    update_message_status(error)
  end

  def should_handle_error?
    @webhook_type == :api_inbox_webhook && SUPPORTED_ERROR_HANDLE_EVENTS.include?(@payload[:event])
  end

  def update_message_status(error)
    message.update!(status: :failed, external_error: error.message)
  end

  def message
    return if message_id.blank?

    @message ||= Message.find_by(id: message_id)
  end

  def message_id
    @payload[:id]
  end
end
