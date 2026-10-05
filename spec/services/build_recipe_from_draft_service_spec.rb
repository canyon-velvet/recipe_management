require "rails_helper"

RSpec.describe BuildRecipeFromDraftService do
  let(:user) { create(:user) }

  def build_recipe(data)
    draft = user.drafts.create!(status: :ready, data: { "name" => "Apple cake", "steps" => [ "Bake it." ] }.merge(data))
    described_class.new(draft).call
  end

  it "copies servings and times from the draft" do
    recipe = build_recipe("servings" => 4, "prep_minutes" => 15, "cook_minutes" => 30, "total_minutes" => 50)

    expect(recipe.attributes.values_at(*Draft::COUNT_KEYS)).to eq [ 4, 15, 30, 50 ]
  end

  it "skips values that aren't positive whole numbers" do
    recipe = build_recipe("servings" => "4", "prep_minutes" => 0, "cook_minutes" => nil, "total_minutes" => 1.5)

    expect(recipe.attributes.values_at(*Draft::COUNT_KEYS)).to all(be_nil)
  end
end
