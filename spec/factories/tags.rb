FactoryBot.define do
  # Pass key and kind: keys are unique, and must be ones from Tag::ICONS because tag names are translated by key
  # (the test env raises on a missing translation).
  factory :tag do
    sequence(:position) { |n| n * 10 }
  end
end
