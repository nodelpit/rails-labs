FactoryBot.define do
  factory :jwt_token do
    association :user
    jti { SecureRandom.uuid }
    exp { 30.days.from_now }
  end
end
