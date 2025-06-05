# Vite Ruby configuration for development
if Rails.env.development?
  # Configure Vite Ruby with increased timeouts for Docker environments
  ViteRuby.configure do |config|
    # Increase timeout for asset compilation and requests
    config.build_timeout = 120 # 2 minutes for build operations
  end

  # Patch Net::HTTP default timeouts for Vite requests
  # This helps prevent Net::ReadTimeout errors when Rails tries to fetch assets from Vite
  module Net
    class HTTP
      alias_method :original_initialize, :initialize
      
      def initialize(address, port = nil)
        original_initialize(address, port)
        
        # Increase timeouts specifically for Vite dev server requests
        if address == 'chatwoot_vite_dev' || port == 3036
          self.open_timeout = 30  # 30 seconds to establish connection
          self.read_timeout = 60  # 60 seconds to read response
        end
      end
    end
  end

  # Add middleware to handle Vite asset failures gracefully
  Rails.application.config.middleware.insert_before ActionDispatch::Static, Class.new do
    def initialize(app)
      @app = app
    end

    def call(env)
      # If this is a Vite asset request that fails, try to serve from public/packs
      if env['PATH_INFO'].start_with?('/vite-dev/')
        begin
          status, headers, body = @app.call(env)
          
          # If Vite request fails (5xx error), try fallback
          if status >= 500
            fallback_path = env['PATH_INFO'].gsub('/vite-dev/', '/packs/')
            env['PATH_INFO'] = fallback_path
            Rails.logger.warn "Vite asset failed, trying fallback: #{fallback_path}"
          end
          
          [status, headers, body]
        rescue => e
          Rails.logger.warn "Vite asset error: #{e.message}"
          # Return 404 instead of 500 for missing assets
          [404, {'Content-Type' => 'text/plain'}, ['Asset not found']]
        end
      else
        @app.call(env)
      end
    end
  end
end 