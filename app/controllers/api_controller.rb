class ApiController < ApplicationController
  skip_before_action :set_current_user, only: [:index]

  def index
    Rails.logger.debug "ApiController#index - Starting health check"
    Rails.logger.debug "ApiController#index - Redis status: #{redis_status}"
    Rails.logger.debug "ApiController#index - PostgreSQL status: #{postgres_status}"
    render json: { version: Chatwoot.config[:version],
                   timestamp: Time.now.utc.to_fs(:db),
                   queue_services: redis_status,
                   data_services: postgres_status }
  end

  private

  def redis_status
    Rails.logger.debug "ApiController#redis_status - Checking Redis connection"
    r = Redis.new(Redis::Config.app)
    return 'ok' if r.ping
  rescue Redis::CannotConnectError => e
    Rails.logger.error "ApiController#redis_status - Redis connection error: #{e.message}"
    'failing'
  end

  def postgres_status
    Rails.logger.debug "ApiController#postgres_status - Checking PostgreSQL connection"
    ActiveRecord::Base.connection.active? ? 'ok' : 'failing'
  rescue ActiveRecord::ConnectionNotEstablished => e
    Rails.logger.error "ApiController#postgres_status - PostgreSQL connection error: #{e.message}"
    'failing'
  end
end
