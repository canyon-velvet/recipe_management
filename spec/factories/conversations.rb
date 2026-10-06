FactoryBot.define do
  factory :conversation do
    user
  end

  factory :message do
    conversation
    role { "user" }
    content { "What can I make with eggs?" }
  end
end
