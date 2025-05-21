class ConfigureShopifyGlobalConfig < ActiveRecord::Migration[7.0]
  def up
    # Create or update the GlobalConfig entry for Shopify client ID
    shopify_client_id = ENV['SHOPIFY_CLIENT_ID']
    shopify_client_secret = ENV['SHOPIFY_CLIENT_SECRET']
    
    if shopify_client_id.present?
      # Check if we have an installation config for this
      client_id_config = InstallationConfig.find_or_initialize_by(name: 'SHOPIFY_CLIENT_ID')
      client_id_config.value = shopify_client_id
      client_id_config.save!
      puts "Set SHOPIFY_CLIENT_ID in InstallationConfig: #{shopify_client_id}"
    end
    
    if shopify_client_secret.present?
      # Check if we have an installation config for this
      client_secret_config = InstallationConfig.find_or_initialize_by(name: 'SHOPIFY_CLIENT_SECRET')
      client_secret_config.value = shopify_client_secret
      client_secret_config.save!
      puts "Set SHOPIFY_CLIENT_SECRET in InstallationConfig: #{shopify_client_secret}"
    end
    
    # Clear the cache to ensure the new values are used
    GlobalConfig.clear_cache if defined?(GlobalConfig)
    puts "Cleared GlobalConfig cache"
  end

  def down
    # Note: We don't want to remove these configs during rollback
    puts "Skipping removal of Shopify configs during rollback"
  end
end 