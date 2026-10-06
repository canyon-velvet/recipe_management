require "rails_helper"

RSpec.describe Assistant::Tools::ShowRecipes do
  let(:user) { create(:user) }
  let(:turn) { Assistant::Turn.new }
  let(:tool) { described_class.new(user, turn) }

  it "shows the recipes found during this reply, in order, each with why it fits" do
    tofu, rice = create_list(:recipe, 2, user: user)
    turn.found([ tofu, rice ])

    result = tool.call({ recipes: [ { id: rice.id, why: " Quick and mild. " }, { id: tofu.id, why: "Spicy." } ] })

    expect(result).to eq(shown: [ rice.id, tofu.id ])
    expect(tool.cards).to eq(rice.id => "Quick and mild.", tofu.id => "Spicy.")

    # Another call replaces the cards
    tool.call({ recipes: [ { id: tofu.id, why: "Spicier." } ] })
    expect(tool.cards).to eq(tofu.id => "Spicier.")
  end

  it "needs a why for every recipe" do
    recipe = create(:recipe, user: user)
    turn.found([ recipe ])

    expect(tool.call({ recipes: [ { id: recipe.id, why: " " } ] })).to eq(error: "Give each recipe a short why.")
    expect(tool.call({ recipes: [ { id: recipe.id } ] })).to eq(error: "Give each recipe a short why.")
    expect(tool.cards).to eq({})
  end

  it "leaves out recipes no tool returned during this reply, such as one remembered from earlier, and says why" do
    found = create(:recipe, user: user)
    remembered = create(:recipe, user: user)
    someone_elses = create(:recipe)
    turn.found([ found ])

    picks = [ remembered, found, someone_elses ].map { |recipe| { id: recipe.id, why: "Good." } }
    result = tool.call({ recipes: picks })

    expect(result).to include(shown: [ found.id ], not_shown: [ remembered.id, someone_elses.id ])
    expect(result[:why]).to include("Look these up first")
    expect(tool.cards).to eq(found.id => "Good.")
  end
end
