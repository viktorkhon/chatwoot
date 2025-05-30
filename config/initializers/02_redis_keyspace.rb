# Configure Redis keyspace notifications for expired events
# This is necessary for features that need to listen to key expiration events

unless Rails.env.test?
  Rails.application.config.after_initialize do
    # Configure the main Redis instances
    begin
      # Get the keyspace notification setting from environment variable or use 'Ex' by default
      # Ex = Keyevent notifications for expired events
      keyspace_setting = ENV.fetch('REDIS_KEYSPACE_NOTIFICATIONS', 'Ex')
      
      # Use a separate connection to set the config to avoid disrupting pooled connections
      redis = Redis.new(Redis::Config.app)
      redis.config('SET', 'notify-keyspace-events', keyspace_setting)
      redis.close
      
      Rails.logger.info "Redis keyspace notifications configured with: #{keyspace_setting}"
    rescue => e
      Rails.logger.error "Failed to configure Redis keyspace notifications: #{e.message}"
    end
  end
end 