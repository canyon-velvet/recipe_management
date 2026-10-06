require "rails_helper"

RSpec.describe Assistant::Tools::ShowRecipes do
  let(:user) { create(:user) }
  let(:tool) { described_class.new(user) }

  it "keeps the user's recipes to show, in order and once each, and says which ids weren't found" do
    tofu, rice = create_list(:recipe, 2, user: user)
    other = create(:recipe)

    expect(tool.call({ ids: [ rice.id, other.id, tofu.id, rice.id ] }))
      .to include(shown: [ rice.id, tofu.id ], not_found: [ other.id ])
    expect(tool.recipe_ids).to eq [ rice.id, tofu.id ]

    # The result tells the model the cards don't replace its reply
    expect(tool.call({ ids: [ rice.id ] })[:next]).to include("Now write your reply: a sentence about each recipe")

    # Another call replaces the cards
    tool.call({ ids: [ tofu.id ] })
    expect(tool.recipe_ids).to eq [ tofu.id ]
  end
end
