class DevToolsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:check_env]
  
  def check_env
    raise ActionController::RoutingError.new('Not Found') if Rails.env.production?
    
    var_name = params[:var_name]
    value = ENV.fetch(var_name, nil)
    
    render json: {
      variable: var_name,
      value: value,
      exists: value.present?
    }
  end
end 