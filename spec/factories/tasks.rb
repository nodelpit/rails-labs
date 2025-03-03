FactoryBot.define do
  factory :task, class: "Api::Task" do
    title { "Exemple de tâche" }
    description { "Description de la tâche" }
    completed { false }
    association :user
  end
end
