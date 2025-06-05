Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end
  config.public_file_server.enabled = true

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = ENV.fetch('ACTIVE_STORAGE_SERVICE', 'local').to_sym

  config.active_job.queue_adapter = :sidekiq

  Rails.application.routes.default_url_options = { host: ENV['FRONTEND_URL'] }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Disable host check during development
  config.hosts = nil

  # Web console configuration for tunnel access
  # Disable web console entirely when accessed through tunnels to avoid IP warnings
  if ENV['FRONTEND_URL']&.include?('trycloudflare.com') || ENV['FRONTEND_URL']&.include?('ngrok.io')
    # Disable web console for tunnel access
    config.web_console.permissions = []
  else
    # Allow web console access from Docker networks and tunnel IPs
    # Include specific Cloudflare IP ranges and common tunnel services
    config.web_console.permissions = [
      '127.0.0.0/8',      # localhost
      '::1',              # IPv6 localhost
      '172.0.0.0/8',      # Docker networks
      '192.168.0.0/16',   # Private networks
      '10.0.0.0/8',       # Private networks
      '66.115.181.0/24',  # Cloudflare tunnel IP range
      '198.41.200.0/24',  # Cloudflare IP range
      '173.245.48.0/20',  # Cloudflare IP range
      '103.21.244.0/22',  # Cloudflare IP range
      '103.22.200.0/22',  # Cloudflare IP range
      '103.31.4.0/22',    # Cloudflare IP range
      '141.101.64.0/18',  # Cloudflare IP range
      '108.162.192.0/18', # Cloudflare IP range
      '190.93.240.0/20',  # Cloudflare IP range
      '188.114.96.0/20',  # Cloudflare IP range
      '197.234.240.0/22', # Cloudflare IP range
      '198.41.128.0/17',  # Cloudflare IP range
      '162.158.0.0/15',   # Cloudflare IP range
      '104.16.0.0/13',    # Cloudflare IP range
      '104.24.0.0/14',    # Cloudflare IP range
      '172.64.0.0/13',    # Cloudflare IP range
      '131.0.72.0/22'     # Cloudflare IP range
    ]
  end

  # customize using the environment variables
  config.log_level = ENV.fetch('LOG_LEVEL', 'debug').to_sym

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  config.logger = ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 1, ENV.fetch('LOG_SIZE', '1024').to_i.megabytes)

  # Bullet configuration to fix the N+1 queries
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end

  # ActionCable configuration for tunnel stability
  config.action_cable.allowed_request_origins = [
    /.*\.trycloudflare\.com.*/,
    /.*\.ngrok\.io.*/,
    /.*\.localhost\.run.*/,
    /.*localhost.*/,
    /.*127\.0\.0\.1.*/
  ]
end
