class Api::BaseController < ApplicationController
  include AccessTokenAuthHelper
  respond_to :json
  before_action :authenticate_access_token!, if: :authenticate_by_access_token?
  before_action :validate_bot_access_token!, if: :authenticate_by_access_token?
  before_action :authenticate_user!, unless: :authenticate_by_access_token?

  private

  def authenticate_by_access_token?
    Rails.logger.debug "Api::BaseController#authenticate_by_access_token? - Checking for access token"
    request.headers[:api_access_token].present? || request.headers[:HTTP_API_ACCESS_TOKEN].present?
  end

  def check_authorization(model = nil)
    Rails.logger.debug "Api::BaseController#check_authorization - Checking authorization for model: #{model}"
    model ||= controller_name.classify.constantize
    authorize(model)
  end

  def check_admin_authorization?
    Rails.logger.debug "Api::BaseController#check_admin_authorization? - Checking admin authorization"
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
