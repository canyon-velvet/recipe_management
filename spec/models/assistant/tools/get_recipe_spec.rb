require "rails_helper"

RSpec.describe Assistant::Tools::GetRecipe do
  let(:user) { create(:user) }
  let(:turn) { Assistant::Turn.new }
  let(:tool) { described_class.new(user, turn) }

  it "reads one of the user's recipes in full, and notes it so it can be shown as a card" do
    recipe = create(:recipe, user: user, name: "Mapo tofu", description: "Numbing", prep_minutes: 10,
                             tags: [ create(:tag, key: "spicy", kind: "flavor") ])
    recipe.recipe_ingredients.create!(ingredient: create(:ingredient, user: user, name: "Tofu"), quantity: "2",
                                      unit: "blocks")

    result = tool.call({ id: recipe.id })

    expect(result).to include(name: "Mapo tofu", description: "Numbing", tags: [ "spicy" ], prep_minutes: 10,
                              ingredients: [ "2 blocks Tofu" ], steps: [ "Cook it." ])
    expect(result).not_to have_key(:avoided)
    expect(turn.found?(recipe.id)).to be true
  end

  it "flags the items on the user's avoid list the recipe contains" do
    recipe = create(:recipe, user: user)
    recipe.recipe_ingredients.create!(ingredient: create(:ingredient, user: user, name: "Peanut butter"))
    create(:preference, user: user, category: "avoid", value: "peanut")

    expect(tool.call({ id: recipe.id })[:avoided]).to eq [ "peanut" ]
  end

  it "can't read another user's recipe" do
    other = create(:recipe)

    expect(tool.call({ id: other.id })).to eq(error: "There's no recipe with id #{other.id}.")
    expect(turn.found?(other.id)).to be false
  end
end
