FactoryBot.define do
  # Use a key from Tag::ICONS: tag names are translated by key, and the test env raises on a missing translation.
  factory :tag do
    key { "dinner" }
    kind { "meal" }
    sequence(:position) { |n| n * 10 }
  end
end
