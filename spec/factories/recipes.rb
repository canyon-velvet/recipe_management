FactoryBot.define do
  factory :recipe do
    user
    source { association :source, user: user }
    sequence(:name) { |n| "Recipe #{n}" }

    # A recipe needs at least one step to be valid.
    after(:build) { |recipe| recipe.steps.build(body: "Cook it.") if recipe.steps.empty? }
  end
end
