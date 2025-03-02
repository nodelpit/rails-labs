FactoryBot.define do
  factory :task do
    title { "Exemple de tâche" }
    description { "Description de la tâche" }
    completed { false }
    association :user
  end
end
