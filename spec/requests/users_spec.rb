require 'rails_helper'

RSpec.describe User, type: :model do
  # Tests de base pour les validations
  describe "validations" do
    # Vérifie que l'email est obligatoire
    it { should validate_presence_of(:email) }

    # Vérifie que l'email est unique (sans tenir compte de la casse)
    it { should validate_uniqueness_of(:email).case_insensitive }

    # Vérifie que le mot de passe est sécurisé
    it { should have_secure_password }

    # Vérifie le format de l'email
    it "rejette les emails invalides" do
      user = build(:user, email: "invalid-email")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    # Vérifie la normalisation de l'email
    it "normalise l'email en minuscules" do
      user = create(:user, email: "TEST@EXAMPLE.COM")
      expect(user.email).to eq("test@example.com")
    end
  end

  # Tests pour les associations
  describe "associations" do
    # Vérifie l'association avec les conversations de chatbot
    it { should have_many(:chatbot_conversations).class_name("Chatbot::Conversation") }

    # Vérifie l'association avec les tokens API et leur suppression en cascade
    it { should have_many(:api_tokens).dependent(:destroy) }
  end

  # Tests pour les rôles d'utilisateur
  describe "rôles" do
    # Vérifie l'enum pour les rôles
    it { should define_enum_for(:role).with_values(user: 0, admin: 1) }

    # Vérifie que le rôle par défaut est 'user'
    it "a 'user' comme rôle par défaut" do
      user = User.new
      expect(user.role).to eq("user")
    end
  end

  # Tests pour la génération de tokens API
  describe "#generate_api_token" do
    let(:user) { create(:user) }

    # Vérifie que les tokens existants sont révoqués
    it "révoque les tokens existants" do
      # Créer quelques tokens d'abord
      3.times { ApiToken.create_for_user(user) }
      expect { user.generate_api_token }.to change { user.api_tokens.count }.from(3).to(1)
    end

    # Vérifie le format et la validité du token généré
    it "retourne un token valide" do
      token_record, raw_token = user.generate_api_token
      expect(token_record).to be_a(Api::Token)
      expect(raw_token).to be_a(String)
      expect(raw_token.length).to eq(64) # 32 octets = 64 caractères hexadécimaux
    end

    # Vérifie la personnalisation de la durée d'expiration
    it "accepte un paramètre d'expiration personnalisé" do
      custom_expiry = 7.days
      token_record, _ = user.generate_api_token(custom_expiry)
      # Vérifie que la date d'expiration est correcte à 1 seconde près
      expect(token_record.expires_at).to be_within(1.second).of(Time.current + custom_expiry)
    end
  end

  # Tests pour la révocation des tokens API
  describe "#revoke_all_api_tokens" do
    let(:user) { create(:user) }

    # Vérifie que tous les tokens sont correctement supprimés
    it "supprime tous les tokens existants" do
      3.times { ApiToken.create_for_user(user) }
      expect { user.revoke_all_api_tokens }.to change { user.api_tokens.count }.from(3).to(0)
    end
  end

  # Tests pour l'autorisation API
  describe "#api_authorized?" do
    # Vérifie que les utilisateurs standards ont accès à l'API
    it "autorise les utilisateurs normaux" do
      user = create(:user, role: :user)
      expect(user.api_authorized?).to be true
    end

    # Vérifie que les administrateurs ont accès à l'API
    it "autorise les administrateurs" do
      admin = create(:user, role: :admin)
      expect(admin.api_authorized?).to be true
    end
  end

  # Tests pour la protection du rôle admin
  describe "protection du rôle admin" do
    before do
      ENV["ADMIN_EMAIL"] = "admin@example.com"
    end

    # Vérifie que l'administrateur principal ne peut pas être rétrogradé
    it "empêche le changement de rôle pour l'administrateur principal" do
      admin = create(:user, email: "admin@example.com", role: :admin)
      admin.role = :user
      expect(admin).not_to be_valid
      expect(admin.errors[:role]).to be_present
    end

    # Vérifie que les autres utilisateurs peuvent changer de rôle
    it "permet le changement de rôle pour les autres utilisateurs" do
      user = create(:user, role: :user)
      user.role = :admin
      expect(user).to be_valid
    end

    after do
      ENV.delete("ADMIN_EMAIL")
    end
  end

  # Tests pour les méthodes de génération de token spécifiques
  describe "génération de tokens" do
    let(:user) { create(:user) }

    # Vérifie la génération du token de réinitialisation de mot de passe
    it "génère un token de réinitialisation de mot de passe" do
      expect(user.generate_token_for(:password_reset)).to be_a(String)
    end

    # Vérifie la génération du token de confirmation d'email
    it "génère un token de confirmation d'email" do
      expect(user.generate_token_for(:email_confirmation)).to be_a(String)
    end

    # Vérifie la génération du token "Se souvenir de moi"
    it "génère un token 'remember_me'" do
      expect(user.generate_token_for(:remember_me)).to be_a(String)
    end
  end

  # Tests pour l'invalidation du token "Se souvenir de moi" lors du changement de mot de passe
  describe "invalidation du token remember_me" do
    let(:user) { create(:user) }

    it "a un mécanisme pour invalider le token remember_me lors du changement de mot de passe" do
      # Vérifie que la méthode privée existe
      expect(user.private_methods).to include(:invalidate_remember_token)

      # Vérifie simplement que le callback est enregistré
      callback_filters = User._save_callbacks.map(&:filter)
      expect(callback_filters).to include(:invalidate_remember_token)
    end
  end
end
