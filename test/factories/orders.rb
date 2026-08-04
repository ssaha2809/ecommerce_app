FactoryBot.define do
  factory :order do
    association :user
    status { "pending" }
    total_cents { 0 }

    trait :confirmed do
      status { "confirmed" }
    end

    trait :shipped do
      status { "shipped" }
    end

    trait :delivered do
      status { "delivered" }
    end

    trait :cancelled do
      status { "cancelled" }
    end
  end

  factory :order_item do
    association :order
    association :product
    quantity { 1 }
    unit_price_cents { 1999 }
  end
end
