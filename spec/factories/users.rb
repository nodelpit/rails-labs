FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "johndoe#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :user }

    trait :admin do
      role { :admin }
    end
  end
end
