FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "cook#{n}" }
    password { "password" }
  end
end
