FactoryBot.define do
  factory :token do
    association :user
    token { Digest::SHA256.hexdigest(SecureRandom.hex(32)) }
    expires_at { 30.days.from_now }
  end
end
