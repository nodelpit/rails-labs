class Api::V2::BaseController < ActionController::API
  # Vérifie que chaque requête contient un token JWT valide
  before_action :authenticate_jwt

  private

  # Extrait et vérifie le token JWT, récupère l'utilisateur associé
  def authenticate_jwt
    header = request.headers["Authorization"]
    token = header.split(" ").last if header&.start_with?("Bearer ")

    @decoded_token = JwtService.decode(token)
    @current_user = User.find(@decoded_token[:user_id]) if @decoded_token

    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
