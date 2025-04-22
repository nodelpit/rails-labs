class Api::V2::AuthController < Api::V2::BaseController
  skip_before_action :authenticate_jwt, only: [ :login ]
  def login
    begin
      validate_login_params

      user = User.find_by(email: params[:email])

      if user&.authenticate(params[:password])
        token = JwtService.encode({ user_id: user.id })
        render json: {
          token: token,
          token_type: "Bearer",
          expires_in: 24.hours.to_i
        }, status: :ok
      else
        render json: { error: "Identifiants invalides" }, status: :unauthorized
      end

    rescue ActionController::ParameterMissing => e
      render json: { error: "Paramètres manquants" }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error("Erreur lors de la connexion: #{e.message}")
      render json: { error: "Une erreur est survenue lors de l\'authentification" }, status: :internal_server_error
    end
  end

  def refresh
    begin
      # S'assurer que le token existe
      return render json: { error: "Token invalide" }, status: :bad_request unless @decoded_token && @decoded_token[:jti]
    end

    # Révoquer l'ancien token
    JwtService.revoke(@decoded_token[:jti])

    # Générer un nouveau token
    token = JwtService.encode({ user_id: current_user.id })

    render json: {
      token: token,
      token_type: "Bearer",
      expires_in: 24.hours.to_i
    }, status: :ok

  rescue JWT::DecodeError => e
    render json: { error: "Erreur de décodage du token" }, status: :unauthorized
  rescue StandardError => e
    Rails.logger.error("Erreur lors du rafraîchissement du token: #{e.message}")
    render json: { error: "Une erreur est survenue lors du rafraîchissement du token" }, status: :internal_server_error
  end

  private

  def validate_login_params
    params.require(:email)
    params.require(:password)

  rescue ActionController::ParameterMissing => e
    raise ActionController::ParameterMissing.new("Le paramètre #{e.message} est requis")
  end
end
