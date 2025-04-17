require Rails.root.join('lib/redis/config')

schedule_file = 'config/schedule.yml'

begin
  Sidekiq.configure_client do |config|
    config.redis = Redis::Config.app
    Rails.logger.info "Sidekiq client configured with Redis: #{Redis::Config.app.inspect}"
  end

  Sidekiq.configure_server do |config|
    config.redis = Redis::Config.app

    # skip the default start stop logging
    if Rails.env.production?
      config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
      config[:skip_default_job_logging] = true
      config.logger.level = Logger.const_get(ENV.fetch('LOG_LEVEL', 'info').upcase.to_s)
    end

    config.on(:startup) do
      Rails.logger.info "Sidekiq server started with Redis config: #{Redis::Config.app.inspect}"
    end

    config.on(:shutdown) do
      Rails.logger.info "Sidekiq server shutting down"
    end

    config.death_handlers << ->(job, ex) do
      Rails.logger.error "Job #{job['jid']} died with error #{ex.message}"
      Rails.logger.error ex.backtrace.join("\n")
    end
  end

  # https://github.com/ondrejbartas/sidekiq-cron
  Rails.application.reloader.to_prepare do
    if File.exist?(schedule_file) && Sidekiq.server?
      begin
        Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
        Rails.logger.info "Successfully loaded Sidekiq cron jobs from #{schedule_file}"
      rescue => e
        Rails.logger.error "Failed to load Sidekiq cron jobs: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
rescue => e
  Rails.logger.error "Failed to configure Sidekiq: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
  raise e
end
