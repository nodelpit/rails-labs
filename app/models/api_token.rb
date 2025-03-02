class ApiToken < ApplicationRecord
  belongs_to :user

  # Valide que les champs obligatoires sont présents
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  attr_accessor :raw_token

  # Portée pour trouver facilement les tokens valides
  scope :valid, -> { where("expires_at > ?", Time.current) }

  # Crée un token et retourne à la fois l'objet et le token brut
  def self.create_for_user(user, expires_in = 30.days)
    raw_token = generate_raw_token
    hashed_token = hash_token(raw_token)

    token = create!(
      user: user,
      token: hashed_token,
      expires_at: Time.current + expires_in
    )

    # Stocker le token brut comme attribut virtuel
    token.raw_token = raw_token

    [ token, raw_token ]
  end

  # Trouve un utilisateur par son token
  def self.find_user_by_token(raw_token)
    return nil if raw_token.blank?

    hashed_token = hash_token(raw_token)
    token = where("token = ? AND expires_at > ?", hashed_token, Time.current).first

    if token
      token.update_column(:last_used_at, Time.current)
      token.user
    else
      nil
    end
  end

  private

  # Génère un token cryptographiquement sécurisé
  def self.generate_raw_token
    SecureRandom.hex(32) # 64 caractères
  end

  # Hache le token pour le stockage sécurisé
  def self.hash_token(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
