class User < ApplicationRecord
  has_secure_password

  # Définition de l'enum pour les rôles
  enum :role, { user: 0, admin: 1 }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: true
  normalizes :email, with: ->(email) { email.strip.downcase }
  validate :prevent_admin_role_change

  def self.human_attribute_name(attribute, *args)
    case attribute.to_sym
    when :password_confirmation, :password_challenge
      ""
    else
      super
    end
  end

  # Pour la réinitialisation du mot de passe
  generates_token_for :password_reset do
    password_salt&.last(10)
  end

  # Pour la confirmation d'email
  generates_token_for :email_confirmation, expires_in: 24.hours do
    email
  end

  # Pour la fonctionnalité "Se souvenir de moi"
  generates_token_for :remember_me, expires_in: 2.weeks do
    # On utilise une combinaison de l'id et du password_salt pour plus de sécurité
    "#{id}-#{password_digest}"
  end

  # Pour éviter les problèmes de sécurité, on invalide le token si le mot de passe change
  after_save :invalidate_remember_token, if: :saved_change_to_password_digest?

  private

  def invalidate_remember_token
    remember_token.token = nil if remember_token
  end

  # méthode privée pour protéger le rôle admin
  def prevent_admin_role_change
    if role_changed? && email == ENV["ADMIN_EMAIL"] && persisted?
      errors.add(:role, I18n.t("activerecord.errors.models.user.attributes.role.admin_change"))
    end
  end
end
