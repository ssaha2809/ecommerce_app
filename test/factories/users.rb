FactoryBot.define do
  factory :user do
    sequence(:name)      { |n| "User #{n}" }
    sequence(:email)     { |n| "user#{n}@example.com" }
    sequence(:api_token) { |n| "token-#{n}-#{SecureRandom.hex(8)}" }
    role { :customer }

    trait :admin do
      role { :admin }
    end
  end
end
