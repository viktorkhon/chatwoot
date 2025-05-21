class EnableShopifyForAllAccounts < ActiveRecord::Migration[7.0]
  def up
    # Enable for existing accounts
    Account.find_each do |account|
      account.enable_features!('shopify_integration') unless account.feature_enabled?('shopify_integration')
    end

    # Set as default for new accounts
    config = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    features = config.value || []

    shopify_feature_config = features.find { |f| (f['name'] || f[:name]) == 'shopify_integration' }

    if shopify_feature_config
      shopify_feature_config['enabled'] = true
      shopify_feature_config[:enabled] = true # Ensure symbol key is also set
    else
      features << { name: 'shopify_integration', enabled: true }
    end

    config.value = features
    config.save!

    # Clear cache to ensure changes take effect immediately
    GlobalConfig.clear_cache if defined?(GlobalConfig)
  end

  def down
    # Revert enabling for existing accounts - this is optional and depends on desired rollback behavior
    # For simplicity, we'll skip disabling for individual accounts in the down migration,
    # as the main goal is to revert the default setting.
    # Account.find_each do |account|
    #   account.disable_features!('shopify_integration')
    # end

    # Remove from default for new accounts
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config&.value.present?
      features = config.value
      features.reject! { |f| (f['name'] || f[:name]) == 'shopify_integration' }
      config.value = features
      config.save!
    end

    GlobalConfig.clear_cache if defined?(GlobalConfig)
  end
end 