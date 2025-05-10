class Shopify::WebhookService
  include HTTParty
  pattr_initialize [:account]

  def send_shopify_name_update(previous_value = nil)
    log_environment_info
    return if webhook_url.blank?

    # Log webhook URL for verification
    Rails.logger.info "🔔 Shopify Webhook: Using webhook URL from ENV: #{webhook_url}"

    payload = {
      event: Events::Types::SHOPIFY_NAME_UPDATED,
      account: {
        id: account.id,
        name: account.name
      },
      shopify_name: {
        value: account.shopify_name,
        previous_value: previous_value
      },
      custom_attributes: account.custom_attributes,
      frontend_url: ENV.fetch('FRONTEND_URL', ''),
      timestamp: Time.now.to_i
    }

    # Log the payload for debugging
    Rails.logger.info "🔔 Shopify Webhook: Sending payload: #{payload.to_json}"

    begin
      response = HTTParty.post(
        webhook_url,
        body: payload.to_json,
        headers: {
          'Content-Type': 'application/json',
          'X-Chatwoot-Signature': generate_signature(payload),
          'X-Chatwoot-Event': Events::Types::SHOPIFY_NAME_UPDATED
        },
        timeout: 5
      )

      if response.success?
        Rails.logger.info "🔔 Shopify Webhook: Successfully sent to #{webhook_url}, Response: #{response.code}"
      else
        Rails.logger.error "🔔 Shopify Webhook: Failed to send webhook: #{response.code} #{response.message}"
      end

      response
    rescue StandardError => e
      Rails.logger.error "🔔 Shopify Webhook: Error sending webhook: #{e.message}"
      nil
    end
  end

  private

  def webhook_url
    url = ENV.fetch('N8N_SHOPIFY_WEBHOOK_URL', nil)
    Rails.logger.info "🔔 Shopify Webhook: Retrieved URL from ENV: #{url || 'nil'}"
    @webhook_url ||= url
  end

  def generate_signature(payload)
    OpenSSL::HMAC.hexdigest(
      'sha256',
      OpenSSL::Digest.new('sha256').hexdigest(account.id.to_s),
      payload.to_json
    )
  end

  def log_environment_info
    Rails.logger.info "🔔 Shopify Webhook: Environment Details"
    Rails.logger.info "🔔 Rails Environment: #{Rails.env}"
    Rails.logger.info "🔔 FRONTEND_URL: #{ENV.fetch('FRONTEND_URL', 'not set')}"
    Rails.logger.info "🔔 N8N_SHOPIFY_WEBHOOK_URL: #{ENV.fetch('N8N_SHOPIFY_WEBHOOK_URL', 'not set')}"
  end
end 