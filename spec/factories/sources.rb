FactoryBot.define do
  factory :source do
    user
    sequence(:name) { |n| "Cookbook #{n}" }
  end
end
