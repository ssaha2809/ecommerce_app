FactoryBot.define do
  factory :cart do
    association :user
  end

  factory :cart_item do
    association :cart
    association :product
    quantity { 1 }
  end
end
