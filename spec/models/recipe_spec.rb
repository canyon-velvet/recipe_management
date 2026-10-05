require "rails_helper"

RSpec.describe Recipe do
  describe "servings and times" do
    it "fills a blank total from prep and cook time" do
      recipe = create(:recipe, prep_minutes: 15, cook_minutes: 30)

      expect(recipe.total_minutes).to eq 45
    end

    it "keeps a total the source gave" do
      recipe = create(:recipe, prep_minutes: 15, cook_minutes: 30, total_minutes: 60)

      expect(recipe.total_minutes).to eq 60
    end

    it "leaves the total blank when prep or cook time is unknown" do
      recipe = create(:recipe, prep_minutes: 15)

      expect(recipe.total_minutes).to be_nil
    end

    it "allows them all to be blank" do
      expect(build(:recipe)).to be_valid
    end

    it "rejects zero, negative, fractional and too-large values" do
      recipe = build(:recipe, servings: 0, prep_minutes: -5, cook_minutes: "1.5", total_minutes: 99_999)

      expect(recipe).not_to be_valid
      expect(recipe.errors.attribute_names).to include(:servings, :prep_minutes, :cook_minutes, :total_minutes)
    end
  end
end
