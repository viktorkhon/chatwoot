class EnableEmailFeaturesForAccounts < ActiveRecord::Migration[7.0]
  def up
    # Get all the active accounts
    accounts = Account.where(status: :active)
    
    puts "Enabling email features for #{accounts.count} accounts"
    
    # Enable required feature flags for each account
    accounts.find_each do |account|
      # These are the required feature flags to see support_email and domain fields in UI
      features_to_enable = ['inbound_emails', 'custom_reply_email', 'custom_reply_domain']
      
      # Check which features are already enabled
      already_enabled = features_to_enable.select { |f| account.feature_enabled?(f) }
      need_to_enable = features_to_enable - already_enabled
      
      if need_to_enable.present?
        account.enable_features!(*need_to_enable)
        puts "Enabled features #{need_to_enable.join(', ')} for account ##{account.id} (#{account.name})"
      else
        puts "Account ##{account.id} (#{account.name}) already has all required features enabled"
      end
    end
    
    # Also update the default features config to make these enabled by default for new accounts
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    
    if config.present?
      features = config.value
      
      # Update the required features to be enabled by default
      ['inbound_emails', 'custom_reply_email', 'custom_reply_domain'].each do |feature_name|
        feature = features.find { |f| f['name'] == feature_name }
        if feature.present?
          feature['enabled'] = true
        else
          features << { 'name' => feature_name, 'enabled' => true }
        end
      end
      
      config.value = features
      config.save!
      puts "Updated ACCOUNT_LEVEL_FEATURE_DEFAULTS to enable email features by default"
      
      # Clear global config cache to ensure updates take effect
      GlobalConfig.clear_cache
    end
  end

  def down
    puts "This migration is not designed to be reversible"
  end
end 