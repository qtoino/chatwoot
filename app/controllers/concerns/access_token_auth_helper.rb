module AccessTokenAuthHelper
  BOT_ACCESSIBLE_ENDPOINTS = {
    'api/v1/accounts/conversations' => %w[toggle_status toggle_priority create update custom_attributes],
    'api/v1/accounts/conversations/messages' => ['create'],
    'api/v1/accounts/conversations/assignments' => ['create']
  }.freeze

  def ensure_access_token
    token = request.headers[:api_access_token] || request.headers[:HTTP_API_ACCESS_TOKEN]
    Rails.logger.info "[ACCESS TOKEN] Header api_access_token: #{request.headers[:api_access_token].present?}"
    Rails.logger.info "[ACCESS TOKEN] Header HTTP_API_ACCESS_TOKEN: #{request.headers[:HTTP_API_ACCESS_TOKEN].present?}"
    Rails.logger.info "[ACCESS TOKEN] Token value: #{token}"
    @access_token = AccessToken.find_by(token: token) if token.present?
    Rails.logger.info "[ACCESS TOKEN] Found access token: #{@access_token.present?}"
  end

  def authenticate_access_token!
    Rails.logger.info '[ACCESS TOKEN] authenticate_access_token! called'
    ensure_access_token
    render_unauthorized('Invalid Access Token') && return if @access_token.blank?

    @resource = @access_token.owner
    Rails.logger.info "[ACCESS TOKEN] Resource type: #{@resource.class.name}"
    Rails.logger.info "[ACCESS TOKEN] Resource ID: #{@resource.id}"
    Current.user = @resource if allowed_current_user_type?(@resource)
    Rails.logger.info "[ACCESS TOKEN] Current.user set: #{Current.user.present?}"
  end

  def allowed_current_user_type?(resource)
    return true if resource.is_a?(User)
    return true if resource.is_a?(AgentBot)

    false
  end

  def validate_bot_access_token!
    return if Current.user.is_a?(User)
    return if agent_bot_accessible?

    render_unauthorized('Access to this endpoint is not authorized for bots')
  end

  def agent_bot_accessible?
    BOT_ACCESSIBLE_ENDPOINTS.fetch(params[:controller], []).include?(params[:action])
  end
end
