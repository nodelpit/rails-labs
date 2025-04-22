# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
if Task.count == 0
  puts "Création de tâches de démo..."
  user = User.first

  5.times do |i|
    user.tasks.create!(
      title: "Tâche exemple #{i+1}",
      description: "Description de la tâche exemple #{i+1}",
      completed: [ true, false ].sample
    )
  end
end

puts "Seed terminée avec succès !"
