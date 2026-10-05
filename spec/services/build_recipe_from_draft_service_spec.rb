require "rails_helper"

RSpec.describe BuildRecipeFromDraftService do
  let(:user) { create(:user) }

  def build_recipe(data)
    base = { "name" => "Apple cake", "source_name" => "Yummy Toddler Food", "steps" => [ "Bake it." ] }
    draft = user.drafts.create!(status: :ready, data: base.merge(data))
    described_class.new(draft).call
  end

  def counts(recipe) = [ recipe.servings, recipe.prep_minutes, recipe.cook_minutes, recipe.total_minutes ]

  it "copies servings and times from the draft" do
    recipe = build_recipe("servings" => 4, "prep_minutes" => 15, "cook_minutes" => 30, "total_minutes" => 50)

    expect(counts(recipe)).to eq [ 4, 15, 30, 50 ]
  end

  it "skips values that aren't whole numbers the recipe can save" do
    recipe = build_recipe("servings" => "4", "prep_minutes" => 0, "cook_minutes" => 99_999_999_999, "total_minutes" => 1.5)

    expect(counts(recipe)).to all(be_nil)
    expect(recipe).to be_valid
  end
end
