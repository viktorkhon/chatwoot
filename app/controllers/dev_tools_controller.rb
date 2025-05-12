class DevToolsController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :require_no_authentication, raise: false
  
  def check_env
    raise ActionController::RoutingError.new('Not Found') if Rails.env.production?
    
    var_name = params[:var_name]
    value = ENV.fetch(var_name, nil)
    
    render json: {
      variable: var_name,
      value: value,
      exists: value.present?
    }
  end

  # Add a debug method to test Shopify webhook
  def test_shopify_webhook
    raise ActionController::RoutingError.new('Not Found') if Rails.env.production?
    
    account_id = params[:account_id] || 2
    account = Account.find(account_id)
    
    previous_value = params[:previous_value] || "test-value-old"
    
    Rails.logger.info "DEBUG: Manual test of Shopify webhook for account ##{account_id}"
    
    # Call the webhook service directly
    result = Shopify::WebhookService.new(account: account).send_shopify_name_update(previous_value)
    
    # Return the result
    render json: {
      account_id: account_id,
      previous_value: previous_value,
      webhook_url: ENV.fetch('N8N_SHOPIFY_WEBHOOK_URL', nil),
      webhook_defined: ENV.key?('N8N_SHOPIFY_WEBHOOK_URL'),
      result: result.present? ? { code: result.code, message: result.message } : "No response (webhook URL not set?)"
    }
  end
end 