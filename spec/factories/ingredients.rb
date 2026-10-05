FactoryBot.define do
  factory :ingredient do
    # Saved, so the user has their default aisles (created after_create) to pick from.
    user { association :user, strategy: :create }
    sequence(:name) { |n| "Ingredient #{n}" }

    # One of the user's default aisles, by key (see Aisle::DEFAULT_KEYS).
    transient { aisle_key { "other" } }
    aisle { user.aisles.find_by!(key: aisle_key) }
  end
end
