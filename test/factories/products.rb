FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    sequence(:sku) { |n| "SKU-#{n}" }
    description { "Sample product description" }
    price_cents { 1999 }
    stock_quantity { 10 }
    association :category

    trait :out_of_stock do
      stock_quantity { 0 }
    end

    trait :expensive do
      price_cents { 99_999 }
    end
  end
end
