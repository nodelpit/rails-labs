require 'rails_helper'

RSpec.describe JwtToken, type: :model do
  # Variable let pour créer un utilisateur qui sera utilisé dans plusieurs tests
  let(:user) { create(:user) }

  # Tests des associations
  describe "associations" do
    it { should belong_to(:user) }
  end

  # Tests des validations
  describe "validations" do
    # Créer un token sans jti
    it "nécessite un jti" do
      token = JwtToken.new(user: user, exp: 1.day.from_now)
      expect(token).not_to be_valid
      expect(token.errors[:jti]).to include("Ce champ ne peut pas être vide")
    end

    it "nécessite un jti unique" do
      # Créer un premier token
      existing_token = create(:jwt_token, user: user)

      # Tente de crée un token avec le meme jti
      duplicate_token = JwtToken.new(
        user: user,
        jti: existing_token.jti,
        exp: 1.day.from_now
      )
      expect(duplicate_token).not_to be_valid
      expect(duplicate_token.errors[:jti]).to include("a déjà été utilisé")
    end

    # Créer un token sans date d'expiration
    it "nécessite une date d'expiration" do
      token = JwtToken.new(user: user, jti: SecureRandom.uuid)
      expect(token).not_to be_valid
      expect(token.errors[:exp]).to include("Ce champ ne peut pas être vide")
    end
  end

  # Tests des scopes
  describe "scopes" do
    let!(:token_valide) { create(:jwt_token, user: user, exp: 1.day.from_now) }
    let!(:token_expire) { create(:jwt_token, user: user, exp: 1.day.ago) }

    describe ".valid" do
      it "retourne uniquement les tokens non expirés" do
        expect(JwtToken.valid).to include(token_valide)
        expect(JwtToken.valid).not_to include(token_expire)
      end
    end

    describe ".expired" do
      it 'retourne uniquement les tokens expirés' do
        expect(JwtToken.expired).to include(token_expire)
        expect(JwtToken.expired).not_to include(token_valide)
      end
    end
  end

  # Tests de la méthode d'instance expired?
  describe "#expired?" do
    it "retourne true pour les tokens expirés" do
      token = create(:jwt_token, user: user, exp: 1.minute.ago)
      expect(token.expired?).to be true
    end

    it "retourne false pour les tokens valide" do
      token = create(:jwt_token, user: user, exp: 1.minute.from_now)
      expect(token.expired?).to be false
    end

    it "retourne true pour les tokens expirant exactement maintenant" do
      fixed_time = Time.new(2023, 1, 1, 12, 0, 0)

      # Token qui expire à cette date fixe
      token = create(:jwt_token, user: user, exp: fixed_time)

      # Voyage exactement à ce moment fixe
      travel_to(fixed_time) do
        expect(token.expired?).to be true
      end
    end
  end
end
