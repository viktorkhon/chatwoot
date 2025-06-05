# config/initializers/cors.rb
# ref: https://github.com/cyu/rack-cors

# font cors issue with CDN
# Ref: https://stackoverflow.com/questions/56960709/rails-font-cors-policy
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/packs/*', headers: :any, methods: [:get, :options]
    resource '/audio/*', headers: :any, methods: [:get, :options]
    # Make the public endpoints accessible to the frontend
    resource '/public/api/*', headers: :any, methods: :any

    if ActiveModel::Type::Boolean.new.cast(ENV.fetch('CW_API_ONLY_SERVER', false)) || Rails.env.development?
      resource '*', headers: :any, methods: :any, expose: %w[access-token client uid expiry]
    end
  end

  # Additional CORS configuration for widget embedding on external domains
  if Rails.env.development?
    allow do
      origins '*'
      # Allow SDK and widget assets to be loaded from external domains
      resource '/packs/js/sdk.js', 
        headers: :any, 
        methods: [:get, :options],
        expose: ['Content-Type', 'Cache-Control'],
        credentials: false
      
      # Allow widget iframe embedding and API calls
      resource '/widget*', 
        headers: :any, 
        methods: [:get, :post, :options],
        credentials: false
      
      # Allow API calls from widgets on external domains
      resource '/api/v1/widget/*', 
        headers: :any, 
        methods: :any,
        credentials: false
        
      # Allow public widget API endpoints
      resource '/public/api/v1/portals/*',
        headers: :any,
        methods: :any,
        credentials: false
        
      # Allow ActionCable websocket connections from external domains
      resource '/cable', 
        headers: :any, 
        methods: [:get, :post, :options],
        credentials: false
        
      # Allow Vite dev server assets (prevent direct port 3036 access)
      resource '/vite-dev/*', 
        headers: :any, 
        methods: [:get, :options],
        credentials: false
    end
    
    # Specific CORS configuration for tunnel domains
    allow do
      origins /.*\.trycloudflare\.com.*/, /.*\.ngrok\.io.*/, /.*\.localhost\.run.*/
      resource '*', 
        headers: :any, 
        methods: :any,
        credentials: false
    end
  end
end

################################################
######### Action Cable Related Config ##########
################################################

# Mount Action Cable outside main process or domain
# Rails.application.config.action_cable.mount_path = nil
# Rails.application.config.action_cable.url = 'wss://example.com/cable'
# Rails.application.config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

# To Enable connecting to the API channel public APIs
# ref : https://medium.com/@emikaijuin/connecting-to-action-cable-without-rails-d39a8aaa52d5
Rails.application.config.action_cable.disable_request_forgery_protection = true

# Allow ActionCable connections from any origin in development for widget embedding
if Rails.env.development?
  Rails.application.config.action_cable.allowed_request_origins = [
    /.*codepen\.io.*/, 
    /.*localhost.*/, 
    /.*127\.0\.0\.1.*/, 
    /.*\.trycloudflare\.com.*/, 
    /.*\.ngrok\.io.*/, 
    /.*\.localhost\.run.*/
  ]
end
