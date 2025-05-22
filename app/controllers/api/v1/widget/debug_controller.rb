require 'socket'

class Api::V1::Widget::DebugController < Api::V1::Widget::BaseController
  skip_before_action :set_web_widget
  skip_before_action :set_contact
  skip_before_action :set_conversation

  def redis
    begin
      # Get the Redis configuration
      redis_config = Redis::Config.app
      redis_client = ::Redis.new(redis_config)
      
      # Test connection
      ping_result = redis_client.ping
      
      # Test port reachability
      redis_url = ENV['REDIS_URL'] || 'redis://127.0.0.1:6379'
      uri = URI.parse(redis_url)
      port_reachable = port_open?(uri.host, uri.port)
      
      # Get redis info
      redis_info = redis_client.info
      
      # Get ENV variable context
      railway_env = {
        railway_environment: ENV.fetch('RAILWAY_ENVIRONMENT', nil),
        redis_url_contains_railway: ENV.fetch('REDIS_URL', '').include?('railway.app'),
        using_railway_config: Redis::Config.railway_valkey?
      }
      
      # Additional connection details
      connection_details = {
        redis_url: ENV['REDIS_URL'] || 'default',
        host: uri.host,
        port: uri.port,
        password_present: !redis_config[:password].nil?,
        connection_successful: ping_result == 'PONG',
        port_reachable: port_reachable,
        config_used: Redis::Config.railway_valkey? ? 'railway_valkey' : (Redis::Config.sentinel? ? 'sentinel' : 'standard'),
        timeout: redis_config[:timeout],
        reconnect_attempts: redis_config[:reconnect_attempts]
      }
      
      # Format Redis info
      formatted_info = {
        version: redis_info['redis_version'],
        uptime_days: redis_info['uptime_in_days'],
        connected_clients: redis_info['connected_clients'],
        used_memory_human: redis_info['used_memory_human'],
        used_memory_peak_human: redis_info['used_memory_peak_human'],
        total_commands_processed: redis_info['total_commands_processed']
      }
      
      render json: { 
        status: 'success', 
        connection: connection_details,
        railway: railway_env,
        redis_info: formatted_info,
        full_redis_info: redis_info
      }
    rescue => e
      render json: { 
        status: 'error', 
        message: e.message, 
        backtrace: e.backtrace.first(5),
        railway_env: {
          railway_environment: ENV.fetch('RAILWAY_ENVIRONMENT', nil),
          redis_url_contains_railway: ENV.fetch('REDIS_URL', '').include?('railway.app')
        },
        redis_url: ENV['REDIS_URL'] || 'default'
      }
    end
  end
  
  private
  
  def port_open?(host, port)
    begin
      socket = TCPSocket.new(host, port)
      socket.close
      true
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
      false
    end
  end
end 