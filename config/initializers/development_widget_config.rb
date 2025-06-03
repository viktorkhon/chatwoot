# Development-specific configuration for widget embedding
# This file is only loaded in development environment

if Rails.env.development?
  # Middleware to remove X-Frame-Options header in development for widget embedding
  class WidgetEmbeddingMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      
      # Remove X-Frame-Options to allow iframe embedding
      headers.delete('X-Frame-Options')
      
      # Ensure proper MIME type for SDK JavaScript
      if env['PATH_INFO'] == '/packs/js/sdk.js'
        headers['Content-Type'] = 'application/javascript; charset=utf-8'
      end
      
      [status, headers, response]
    end
  end

  # Insert the middleware
  Rails.application.config.middleware.use WidgetEmbeddingMiddleware
  
  # Additional security configurations for development
  Rails.application.config.force_ssl = false
  
  # Allow all origins for ActionCable in development
  Rails.application.config.action_cable.allowed_request_origins = nil
  
  Rails.logger.info "🔧 Development widget embedding configuration loaded - iframe embedding enabled for external domains"
end 