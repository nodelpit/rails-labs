class Api::V1::BaseController < ActionController::API
  before_action :authenticate_with_api_token

  private

  def authenticate_with_api_token
    # Récupérer le token de différentes sources
    api_token = session[:api_token] ||  request.headers["X-Api-Token"] ||  params[:api_token]

    @current_user = ApiToken.find_user_by_token(api_token)

    unless @current_user&.api_authorized?
      render json: {
        error: "Unauthorized",
        details: {
          token_present: api_token.present?,
          user_found: @current_user.present?,
          user_authorized: @current_user&.api_authorized?
        }
      }, status: :unauthorized
    end
  end

  def current_user
    @current_user
  end
end
