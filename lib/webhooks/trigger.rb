class Webhooks::Trigger
  SUPPORTED_ERROR_HANDLE_EVENTS = %w[message_created message_updated].freeze

  def initialize(url, payload, webhook_type)
    @url = url
    @payload = payload
    @webhook_type = webhook_type
  end

  def self.execute(url, payload, webhook_type)
    new(url, payload, webhook_type).execute
  end

  def execute
    Rails.logger.debug "Webhooks::Trigger#execute - Sending webhook to #{@url}"
    Rails.logger.debug "Webhooks::Trigger#execute - Payload: #{@payload.inspect}"
    Rails.logger.debug "Webhooks::Trigger#execute - Webhook type: #{@webhook_type}"
    
    response = perform_request
    Rails.logger.debug "Webhooks::Trigger#execute - Response: #{response.inspect}"
    response
  rescue StandardError => e
    Rails.logger.error "Webhooks::Trigger#execute - Error: #{e.class.name} - #{e.message}"
    Rails.logger.error "Webhooks::Trigger#execute - Backtrace: #{e.backtrace.join("\n")}"
    handle_error(e)
    Rails.logger.warn "Exception: Invalid webhook URL #{@url} : #{e.message}"
  end

  private

  def perform_request
    RestClient::Request.execute(
      method: :post,
      url: @url,
      payload: @payload.to_json,
      headers: { content_type: :json, accept: :json },
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
