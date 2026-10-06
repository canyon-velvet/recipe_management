require "rails_helper"

RSpec.describe Assistant::Tools::ShowRecipes do
  let(:user) { create(:user) }
  let(:turn) { Assistant::Turn.new }
  let(:tool) { described_class.new(user, turn) }

  it "shows the recipes found during this reply, in order and once each" do
    tofu, rice = create_list(:recipe, 2, user: user)
    turn.found([ tofu, rice ])

    result = tool.call({ ids: [ rice.id, tofu.id, rice.id ] })

    expect(result).to include(shown: [ rice.id, tofu.id ])
    expect(result).not_to have_key(:not_shown)
    expect(tool.recipe_ids).to eq [ rice.id, tofu.id ]
    # The result tells the model the cards don't replace its reply
    expect(result[:next]).to include("Now write your reply: a sentence about each recipe")

    # Another call replaces the cards
    tool.call({ ids: [ tofu.id ] })
    expect(tool.recipe_ids).to eq [ tofu.id ]
  end

  it "leaves out recipes no tool returned during this reply, such as one remembered from earlier, and says why" do
    found = create(:recipe, user: user)
    remembered = create(:recipe, user: user)
    someone_elses = create(:recipe)
    turn.found([ found ])

    result = tool.call({ ids: [ remembered.id, found.id, someone_elses.id, 999_999 ] })

    expect(result).to include(shown: [ found.id ], not_shown: [ remembered.id, someone_elses.id, 999_999 ])
    expect(result[:why]).to include("Look these up first")
    expect(tool.recipe_ids).to eq [ found.id ]
  end
end
