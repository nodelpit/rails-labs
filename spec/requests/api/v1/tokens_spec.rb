require 'rails_helper'

RSpec.describe "Api::V1::Tokens", type: :request do
  let(:user) { create(:user, email: "test@example.com", password: "password123") }
  let(:valid_credentials) { { email: user.email, password: "password123" } }
  let(:invalid_email) { { email: "wrong@example.com", password: "password123" } }
  let(:invalid_password) { { email: user.email, password: "wrongpassword" } }
  let!(:existing_token) { user.generate_api_token[1] } # Génère un token pour les tests de révocation

  describe "GET /api/v1/token (create)" do
    context "avec des identifiants valides" do
      it "génère un nouveau token API et renvoie un statut 201 Created" do
        post api_v1_token_path, params: valid_credentials

        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)

        expect(json_response["api_token"]).to be_present
        expect(json_response["expires_in"]).to eq(30.days.to_i)
      end

      it "révoque tous les tokens précédents de l'utilisateur" do
        # Stocker le hash du token existant
        old_token_hash = Digest::SHA256.hexdigest(existing_token)

        # Générer un nouveau token
        post api_v1_token_path, params: valid_credentials

        # Vérifier que le token précédent a été révoqué
        expect(ApiToken.find_by(token: old_token_hash)).to be_nil
      end
    end

    context "avec un email invalide" do
      it "renvoie une erreur 401 Unauthorized et un message d'erreur" do
        post api_v1_token_path, params: invalid_email

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid credentials")
      end
    end

    context "avec un mot de passe invalide" do
      it "renvoie une erreur 401 Unauthorized et un message d'erreur" do
        post api_v1_token_path, params: invalid_password

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid credentials")
      end
    end
  end

  describe "DELETE /api/v1/token (destroy)" do
    context "lorsque l'utilisateur est authentifié" do
      it "révoque tous les tokens de l'utilisateur et renvoie un statut 200 OK" do
        # S'assurer qu'il existe au moins un token
        expect(user.api_tokens.count).to be >= 1

        # Envoyer la requête de révocation avec le token d'authentification
        delete api_v1_token_path, headers: { "X-Api-Token" => existing_token }
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("API tokens révoqués")

        # Vérifier que les tokens ont été révoqués
        expect(user.api_tokens.reload.count).to eq(0)
      end
    end

    context "lorsque l'utilisateur n'est pas authentifié" do
      it "renvoie une erreur 401 Unauthorized" do
        delete api_v1_token_path

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
