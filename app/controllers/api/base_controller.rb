class Api::BaseController < ApplicationController
  include AccessTokenAuthHelper
  respond_to :json
  before_action :authenticate_access_token!, if: :authenticate_by_access_token?
  before_action :validate_bot_access_token!, if: :authenticate_by_access_token?
  before_action :authenticate_user!, unless: :authenticate_by_access_token?

  private

  def authenticate_by_access_token?
    Rails.logger.info "[API BASE] All headers: #{request.headers.to_h.keys.grep(/api_access_token/i)}"
    Rails.logger.info "[API BASE] api_access_token header: #{request.headers[:api_access_token].inspect}"
    Rails.logger.info "[API BASE] HTTP_API_ACCESS_TOKEN header: #{request.headers[:HTTP_API_ACCESS_TOKEN].inspect}"
    Rails.logger.info "[API BASE] Api-Access-Token header: #{request.headers['Api-Access-Token'].inspect}"
    result = request.headers[:api_access_token].present? || request.headers[:HTTP_API_ACCESS_TOKEN].present?
    Rails.logger.info "[API BASE] authenticate_by_access_token? result: #{result}"
    result
  end

  def check_authorization(model = nil)
    model ||= controller_name.classify.constantize

    authorize(model)
  end

  def check_admin_authorization?
    raise Pundit::NotAuthorizedError unless Current.account_user.administrator?
  end
end
