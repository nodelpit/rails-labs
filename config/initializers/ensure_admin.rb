Rails.application.config.after_initialize do
  # Ne s'exécute que si la variable d'environnement ADMIN_EMAIL est définie
  if admin_email = ENV["ADMIN_EMAIL"]
    admin = User.find_by(email: admin_email)

    # Si l'utilisateur existe mais n'est pas admin
    if admin && admin.role != "admin" && admin.role != 1
      # Met à jour directement avec SQL pour éviter les validations
      ActiveRecord::Base.connection.execute("UPDATE users SET role = 1 WHERE email = '#{admin_email}'")
      Rails.logger.info "✅ Utilisateur #{admin_email} promu administrateur"
    end
  end
end
