FactoryBot.define do
  factory :preference do
    user
    category { "likes" }
    sequence(:value) { |n| "Flavor #{n}" }
  end
end
