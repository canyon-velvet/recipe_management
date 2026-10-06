require "rails_helper"

RSpec.describe Assistant::Tools::GetRecipe do
  let(:user) { create(:user) }
  let(:tool) { described_class.new(user) }

  it "reads one of the user's recipes in full" do
    recipe = create(:recipe, user: user, name: "Mapo tofu", description: "Numbing", prep_minutes: 10,
                             tags: [ create(:tag, key: "spicy", kind: "flavor") ])
    recipe.recipe_ingredients.create!(ingredient: create(:ingredient, user: user, name: "Tofu"), quantity: "2",
                                      unit: "blocks")

    expect(tool.call({ id: recipe.id })).to include(
      name: "Mapo tofu", description: "Numbing", tags: [ "spicy" ], prep_minutes: 10,
      ingredients: [ "2 blocks Tofu" ], steps: [ "Cook it." ]
    )
  end

  it "can't read another user's recipe" do
    other = create(:recipe)

    expect(tool.call({ id: other.id })).to eq(error: "There's no recipe with id #{other.id}.")
  end
end
