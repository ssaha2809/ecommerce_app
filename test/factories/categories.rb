FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    description { "Sample category description" }
  end
end
