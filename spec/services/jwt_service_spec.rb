require 'rails_helper'

RSpec.describe JwtService, type: :service do
  let(:user) { create(:user) }
  let(:payload) { { user_id: user.id } }

  describe '.encode' do
    it "génère un token JWT valide" do
      token = JwtService.encode(payload)
      expect(token).to be_a (String)
      expect(token.split('.').length).to eq(3) # Format JWT standard: header.payload.signature
    end

    it "crée un enregistrement JwtToken dans la base de données" do
      expect { JwtService.encode(payload) }.to change(JwtToken, :count).by(1)
    end

    it "stocke le jti et l'expiration dans le JwtToken" do
      token = JwtService.encode(payload)
      jwt_token = JwtToken.last

      # Decode le token pour verifier les valeurs
      decoded = JWT.decode(token, JwtService::SECRECT_KEY)[0]

      expect(jwt_token.jti).to eq(decoded['jti'])
      expect(jwt_token.exp.to_i).to eq(decoded['exp'])
      expect(jwt_token.user_id).to eq(user.id)
    end

    it "joute les claims standard au payload" do
      token = JwtService.encode(payload)
      decoded = JWT.decode(token, JwtService::SECRECT_KEY)[0]

      expect(decoded).to include("exp", "jti", "iat")
      expect(decoded['user_id']).to eq(user.id)
    end
  end

  describe ".decode" do
    let(:token) { JwtService.encode(payload) }

    it "decode un token valide et retourne le payload" do
      decoded = JwtService.decode(token)
      expect(decoded).to be_a(HashWithIndifferentAccess)
      expect(decoded[:user_id]).to eq(user.id)
      expect(decoded[:jti]).to be_present
    end

    it "retourne nil pour un token nil ou vide" do
      expect(JwtService.decode(nil)).to be_nil
      expect(JwtService.decode('')).to be_nil
    end

    it "retourne nil pour un token avec une signature invalide" do
      # Manipuler le token pour simuler une signature invalide
      invalid_token = token.split('.').tap { |parts| parts[2] = "invalid_signature" }.join('.')
      expect(JwtService.decode(invalid_token)).to be_nil
    end

    it "retourne nil si le token n'existe pas en base de données" do
      # Supprimer le token de la base de données
      decoded = JWT.decode(token, JwtService::SECRECT_KEY)[0]
      JwtToken.find_by(jti: decoded['jti']).destroy

      expect(JwtService.decode(token)).to be_nil
    end

    it 'retourne nil si le token est expiré' do
      # Créer un token qui expire immédiatement
      expiring_token = JwtService.encode(payload, 0.seconds.from_now)

      # Attendre que le token expire
      travel_to(1.second.from_now) do
        expect(JwtService.decode(expiring_token)).to be_nil
      end
    end
  end

  describe '.revoke' do
    it "revoque un token en modifiant sa date d'expiration" do
      # Encoder un token pour obtenir un JwtToken
      token = JwtService.encode(payload)
      decoded = JWT.decode(token, JwtService::SECRECT_KEY)[0]
      jti = decoded['jti']

      # Vérifier que le token est valide avant révocation
      jwt_token = JwtToken.find_by(jti: jti)
      expect(jwt_token.expired?).to be false

      # Revoquer le token
      JwtService.revoke(jti)

      # Verifier que le token est maintenant expiré
      expect(jwt_token.reload.expired?).to be true
    end

    it "ne fait rien si le jti n'existe pas" do
      expect { JwtService.revoke('jti_inexistant') }.not_to raise_error
    end
  end
end
