class ShopifyWebhookListener < BaseListener
  include Singleton
  
  # This method matches the event name after conversion from 'shopify_name.updated' to 'shopify_name_updated'
  def shopify_name_updated(event)
    account_shopify_name_updated(event)
  end
  
  def account_shopify_name_updated(event)
    shopify_name_change = event.data[:shopify_name_change]
    account = event.data[:account]

    return if shopify_name_change.blank? || account.blank?

    # Get previous value
    previous_value = shopify_name_change[0]
    current_value = shopify_name_change[1]

    # Log the event
    Rails.logger.info "🔔 ShopifyWebhookListener: Processing shopify_name update for account ##{account.id}"
    Rails.logger.info "🔔 ShopifyWebhookListener: Shopify name changed from '#{previous_value}' to '#{current_value}'"
    
    # Log the webhook URL from ENV
    webhook_url = ENV.fetch('N8N_SHOPIFY_WEBHOOK_URL', nil)
    
    # Only trigger if there's an actual change
    return if previous_value == current_value

    Shopify::WebhookService.new(account: account).send_shopify_name_update(previous_value)
  end
end