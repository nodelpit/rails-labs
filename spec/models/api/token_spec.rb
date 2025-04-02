require 'rails_helper'

RSpec.describe Api::Token, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it 'requires a token' do
      token = Api::Token.new(user: user, expires_at: 30.days.from_now)
      expect(token).not_to be_valid
      expect(token.errors[:token]).to include("Ce champ ne peut pas être vide")
    end

    it 'requires a unique token' do
      existing_token = create(:api_token, user: user) # Factory doit être `api_token`
      duplicate_token = Api::Token.new(
        user: user,
        token: existing_token.token,
        expires_at: 30.days.from_now
      )
      expect(duplicate_token).not_to be_valid
      expect(duplicate_token.errors[:token]).to include("Ce token a déjà été utilisé")
    end

    it 'requires an expiration date' do
      token = Api::Token.new(user: user, token: 'some_token')
      expect(token).not_to be_valid
      expect(token.errors[:expires_at]).to include("La date d'expiration ne peut pas être vide")
    end
  end

  describe '.find_user_by_token' do
    it 'returns nil for expired token' do
      # Créer un token qui expire dans 1 seconde
      token, raw_token = Api::Token.create_for_user(user, 1.second)

      # Attendre que le token expire
      travel_to(2.seconds.from_now) do
        # Vérifier explicitement que le token est expiré
        expect(token.reload.expires_at).to be < Time.current

        # Vérifier que find_user_by_token retourne nil
        expect(Api::Token.find_user_by_token(raw_token)).to be_nil
      end
    end
  end
end
