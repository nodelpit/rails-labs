require 'rails_helper'

RSpec.describe Api::V2::AuthController, type: :request do
  let(:user) { create(:user) }
  let(:valid_login_params) { { email: user.email, password: 'password123' } }
  let(:invalid_login_params) { { email: user.email, password: 'wrong_password' } }

  describe "POST api_v2_auth_login" do
    context "avec des identifiants valides" do
      it "retourne un token JWT et des informations sur l'expiration" do
        post api_v2_auth_login_path, params: valid_login_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response).to include("token", "token_type", "expires_in")
        expect(json_response["token_type"]).to eq("Bearer")
        expect(json_response["expires_in"]).to eq(24.hours.to_i)

        # Vérifier que le token est valide
        token = json_response["token"]
        expect(JwtService.decode(token)).not_to be_nil
      end
    end

    context "avec des identifiants invalides" do
      it "retourne une erreur d'authentification" do
        post api_v2_auth_login_path, params: invalid_login_params

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)

        expect(json_response["error"]).to eq("Identifiants invalides")
      end
    end

    context "avec des paramètres manquants" do
      it "retourne une erreur de requête" do
        post api_v2_auth_login_path, params: { email: user.email }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)

        expect(json_response["error"]).to eq("Paramètres manquants")
      end
    end
  end

  describe "POST /api/v2/auth/refresh" do
    let(:payload) { { user_id: user.id } }
    let(:token) { JwtService.encode(payload) }
    let(:decoded_token) { JwtService.decode(token) }

    context "avec un token valide" do
      it "révoque l'ancien token et génère un nouveau token" do
        # Garder une trace du jti original pour vérifier qu'il est révoqué
        original_jti = decoded_token[:jti]

        # Appeler l'endpoint de rafraîchissement
        post api_v2_auth_refresh_path, headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        # Vérifier la structure de la réponse
        expect(json_response).to include("token", "token_type", "expires_in")
        expect(json_response["token_type"]).to eq("Bearer")
        expect(json_response["expires_in"]).to eq(24.hours.to_i)

        # Vérifier que le nouveau token est différent de l'ancien
        expect(json_response["token"]).not_to eq(token)

        # Vérifier que l'ancien token n'est plus valide
        expect(JwtService.decode(token)).to be_nil

        # Vérifier que le nouveau token est valide
        new_token = json_response["token"]
        expect(JwtService.decode(new_token)).not_to be_nil
      end
    end

    context "sans token d'authentification" do
      it "retourne une erreur non autorisé" do
        post api_v2_auth_refresh_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "avec un token invalide" do
      it "retourne une erreur non autorisé" do
        # Manipuler le token pour le rendre invalide
        invalid_token = token.split('.').tap { |parts| parts[2] = "invalid_signature" }.join('.')

        post api_v2_auth_refresh_path, headers: { "Authorization" => "Bearer #{invalid_token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "avec un token expiré" do
      it "retourne une erreur non autorisé" do
        # Créer un token qui expire immédiatement
        expiring_token = JwtService.encode(payload, 0.seconds.from_now)

        travel_to(1.second.from_now) do
          post api_v2_auth_refresh_path, headers: { "Authorization" => "Bearer #{expiring_token}" }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context "avec un token révoqué" do
      it "retourne une erreur non autorisé" do
        # Révoquer le token
        JwtService.revoke(decoded_token[:jti])

        post api_v2_auth_refresh_path, headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
