module Auth
  module Authentication
    extend ActiveSupport::Concern

    included do
      helper_method :current_user
      helper_method :user_signed_in?
      before_action :login_from_cookie
    end

    private

    # Récupère l'utilisateur depuis le cookie "Remember me"
    def login_from_cookie
      return if current_user
      if (user_id = cookies.encrypted[:remember_user_token])
        if (user = User.find_by(id: user_id))
          login user
        end
      end
    end

    # Récupère l'utilisateur correspondant à l'ID stocké en session
    def authenticate_user_from_session
      User.find_by(id: session[:user_id])
    end

    # Retourne l'utilisateur actuellement connecté
    def current_user
      Current.user ||= authenticate_user_from_session
    end

    # Vérifie si un utilisateur est connecté
    def user_signed_in?
      current_user.present?
    end

    # Redirige vers la page d'accueil si l'utilisateur n'est pas connecté
    def authenticate_user!
      redirect_to root_path, alert: t("auth.authentication.login_required") unless user_signed_in?
    end

    # Connecte l'utilisateur et initialise sa session
    def login(user)
      Current.user = user
      reset_session
      session[:user_id] = user.id

      # Révoquer tous les tokens existants et générer un nouveau token
      user.revoke_all_api_tokens
      _, raw_token = user.generate_api_token

      # Stocker le nouveau token dans la session
      session[:api_token] = raw_token

      # Gérer le cookie "Remember me" si l'option est cochée
      if params[:remember_me] == "1"
        cookies.encrypted[:remember_user_token] = {
          value: user.id,
          expires: 2.weeks.from_now,
          httponly: true,
          secure: Rails.env.production?
        }
      end
    end

    # Déconnecte l'utilisateur et réinitialise sa session
    def logout(user)
      Current.user = nil
      reset_session
      cookies.delete(:remember_user_token)
    end
  end
end
