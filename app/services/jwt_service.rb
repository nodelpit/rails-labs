class JwtService
  # Utilise la clé secrète de l'application Rails pour signer et vérifier les tokens
  SECRECT_KEY = Rails.application.credentials.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    jti = SecureRandom.uuid

    # Stocke le token dans la bdd
    JwtToken.create!(
      user_id: payload[:user_id],
      jti: jti,
      exp: exp
    )

    # Crée le payload avec les claims standard
    payload[:exp] = exp.to_i # Expiration Time
    payload[:jti] = jti # JWT ID
    payload[:iat] = Time.current.to_i # Issued At

    # Encode le token
    JWT.encode(payload, SECRECT_KEY)
  end

  def self.decode(token)
    return nil unless token

    decoded = JWT.decode(token, SECRECT_KEY)[0]
    token_data = HashWithIndifferentAccess.new(decoded)

    # Vérifie que le token existe en bdd et n'est pas expiré
    jwt_token = JwtToken.find_by(jti: token_data[:jti])
    return nil unless jwt_token && !jwt_token.expired?

    token_data
  rescue JWT::DecodeError
    nil
  end

  # Révoque un token en le marquant comme expiré dans la base de données
  def self.revoke(jti)
    token = JwtToken.find_by(jti: jti)
    token.update(exp: Time.current - 1.second) if token
  end
end
