require 'rails_helper'

RSpec.describe "Api::V2::Bases", type: :request do
  let(:user) { create(:user) }
  let(:payload) { { user_id: user.id } }
  let(:token) { JwtService.encode(payload) }

  describe "Authentification avec token JWT" do
    context "lorsque l'authentification réussit" do
      it "authentifie avec un JWT valide dans l'en-tete" do
        get api_v2_tasks_path, headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:success)
      end
    end

    context "lorsque l'authentification échoue" do
      it "renvoie 'non autorisé' quand aucun token n'est fourni" do
        get api_v2_tasks_path
        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq('Unauthorized')
      end

      it "renvoie 'non autorisé' avec un token mal formaté" do
        get api_v2_tasks_path, headers: { "Authorization" => "Invalid #{token}" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "renvoie 'non autorisé' avec un token invalide" do
        # Manipuler le token pour le rendre invalide
        invalid_token = token.split('.').tap { |parts| parts[2] = "invalid_signature" }.join('.')

        get api_v2_tasks_path, headers: { "Authorization" => "Bearer #{invalid_token}" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "renvoie 'non autorisé' avec un token expiré" do
        # Créer un token qui expire immédiatement
        expiring_token = JwtService.encode(payload, 0.seconds.from_now)

        travel_to(1.second.from_now) do
          get api_v2_tasks_path, headers: { "Authorization" => "Bearer #{expiring_token}" }
          expect(response).to have_http_status(:unauthorized)
        end
      end

      it "renvoie 'non autorisé' avec un token révoqué" do
        # Encoder un token puis le révoquer
        revoked_token = JwtService.encode(payload)
        decoded = JWT.decode(revoked_token, JwtService::SECRECT_KEY)[0]
        jti = decoded['jti']

        # Révoquer le token
        JwtService.revoke(jti)

        get api_v2_tasks_path, headers: { "Authorization" => "Bearer #{revoked_token}" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "renvoie 'non autorisé' si l'utilisateur n'existe pas dans la base de données" do
        # Modifie le token pour contenir un ID utilisateur qui n'existe pas
        # On peut trouver un ID qui n'existe certainement pas en prenant le max ID + 1
        non_existent_id = User.maximum(:id).to_i + 1000

        # Créer un token directement sans passer par la méthode encode
        fake_payload = {
          user_id: non_existent_id,
          jti: SecureRandom.uuid,
          exp: 30.minutes.from_now.to_i,
          iat: Time.current.to_i
        }
        fake_token = JWT.encode(fake_payload, JwtService::SECRECT_KEY)

        # Tenter d'accéder avec ce token
        get api_v2_tasks_path, headers: { "Authorization" => "Bearer #{fake_token}" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "Méthode current_user" do
    it "permet d'accéder aux ressources de l'utilisateur authentifié" do
      task = create(:task, user: user)

      # Accéder à la tâche crée via l'API
      get api_v2_task_path(task), headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:success)
    end
  end
end
