FactoryBot.define do
  factory :ingredient do
    user
    sequence(:name) { |n| "Ingredient #{n}" }

    # One of the user's default aisles, by key (see Aisle::DEFAULT_KEYS).
    transient { aisle_key { "other" } }
    aisle { user.aisles.find_by!(key: aisle_key) }
  end
end
