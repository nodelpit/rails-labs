require 'rails_helper'

RSpec.describe "Api::V1::Bases", type: :request do
  let(:user) { create(:user) }
  let!(:token) { user.generate_api_token[1] } # Récupération du token brut
  let!(:task) { Task.create(title: "Test Task", description: "Test Description") }

  describe "Authentification avec token API" do
    # Teste l'authentification via le header HTTP standard pour les API tokens
    context "lorsque l'authentification réussit" do
      it "authentifie avec le token dans l'en-tête" do
        get api_v1_tasks_path, headers: { "X-Api-Token" => token }
        expect(response).to have_http_status(:success)
      end

      # Teste l'authentification via les paramètres de requête, utile pour certains clients API
      it "authentifie avec le token dans les paramètres" do
        get api_v1_tasks_path, params: { api_token: token }
        expect(response).to have_http_status(:success)
      end

      # Teste l'authentification via la session, important pour les accès API depuis le navigateur
      it "authentifie avec le token dans la session" do
        # D'abord se connecter pour définir la session
        post auth_session_path, params: {
          email: user.email,
          password: "password123"
         }
        # Puis accéder à l'API
        get api_v1_tasks_path
        expect(response).to have_http_status(:success)
      end
    end

    context "lorsque l'authentification échoue" do
      # Vérifie le comportement lorsqu'aucun token n'est fourni
      it "renvoie 'non autorisé' quand aucun token n'est fourni" do
        get api_v1_tasks_path
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Unauthorized")
        # Vérifie que le détail indique correctement l'absence de token
        expect(json_response["details"]["token_present"]).to be_falsey
      end

      # Vérifie le comportement avec un token qui n'existe pas dans la base de données
      it "renvoie 'non autorisé' quand un token invalide est fourni" do
        get api_v1_tasks_path, headers: { "X-Api-Token" => "token_invalide" }
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        # Vérifie que le token a bien été reçu mais qu'aucun utilisateur n'a été trouvé
        expect(json_response["details"]["token_present"]).to be_truthy
        expect(json_response["details"]["user_found"]).to be_falsey
      end

      # Vérifie le comportement avec un token expiré
      it "renvoie 'non autorisé' quand le token est expiré" do
        token_expire = SecureRandom.hex(32)
        Token.create!(
          user: user,
          token: Digest::SHA256.hexdigest(token_expire),
          expires_at: 1.day.ago
        )

        # Requête API avec le token expiré
        get api_v1_tasks_path, headers: { "X-Api-Token" => token_expire }
        expect(response).to have_http_status(:unauthorized)
      end

      # Vérifie le comportement avec un token qui a été révoqué
      it "renvoie 'non autorisé' quand le token a été révoqué" do
        # Stocker le token
        ancien_token = token

        # Supprimer directement le token pour simuler la révocation
        Token.where(token: Digest::SHA256.hexdigest(ancien_token)).delete_all

        # Vérifier que l'authentification échoue
        get api_v1_tasks_path, headers: { "X-Api-Token" => ancien_token }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "lorsque l'utilisateur n'est pas autorisé pour l'accès API" do
      # Prépare un utilisateur qui a un token valide mais qui n'est pas autorisé pour l'API
      let(:utilisateur_non_autorise) { create(:user) }
      let!(:token_non_autorise) { utilisateur_non_autorise.generate_api_token[1] }

      before do
        # Rendre cet utilisateur spécifiquement non autorisé pour l'API
        allow_any_instance_of(User).to receive(:api_authorized?).and_return(false)
      end

      # Vérifie que même avec un token valide, l'autorisation est nécessaire
      it "renvoie 'non autorisé' avec des informations détaillées" do
        get api_v1_tasks_path, headers: { "X-Api-Token" => token_non_autorise }
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        # Vérifie les détails spécifiques de l'erreur d'autorisation
        expect(json_response["details"]["token_present"]).to be_truthy
        expect(json_response["details"]["user_found"]).to be_truthy
        expect(json_response["details"]["user_authorized"]).to be_falsey
      end
    end
  end

  # Tests pour la méthode current_user fournie par le contrôleur de base
  describe "Fonctionnalité current_user" do
    # Vérifie que l'utilisateur authentifié est correctement utilisé tout au long de la requête
    it "utilise l'utilisateur authentifié tout au long de la requête" do
      # Associer la tâche à l'utilisateur authentifié
      tache = Task.create(title: "Tâche de l'utilisateur", user: user)

      get api_v1_task_path(tache), headers: { "X-Api-Token" => token }
      expect(response).to have_http_status(:success)
    end
  end
end
