class EnableChatwootV4FeatureFlag < ActiveRecord::Migration[7.0]
  def up
    # Update the default feature flag config to enable chatwoot_v4
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      features = config.value.map do |f|
        if f['name'] == 'chatwoot_v4'
          f.merge('enabled' => true)
        else
          f
        end
      end
      config.value = features
      config.save!
    end

    # Enable chatwoot_v4 for all accounts in batches of 100
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('chatwoot_v4') }
    end

    # Clear cache to ensure changes take effect immediately
    GlobalConfig.clear_cache if defined?(GlobalConfig)
  end

  def down
    # Update the default feature flag config to disable chatwoot_v4
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      features = config.value.map do |f|
        if f['name'] == 'chatwoot_v4'
          f.merge('enabled' => false)
        else
          f
        end
      end
      config.value = features
      config.save!
    end

    # No need to disable the flag for existing accounts in down migration
    # as it would be disruptive to remove the feature from existing accounts
  end
end 