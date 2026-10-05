require "rails_helper"

RSpec.describe RecipesHelper, type: :helper do
  describe "#recipe_facts" do
    it "lists only what's known" do
      recipe = build(:recipe, servings: 4, cook_minutes: 75)

      expect(helper.recipe_facts(recipe)).to eq [ "Serves 4", "Cook 1 hr 15 min" ]
    end

    it "is empty when nothing is known" do
      expect(helper.recipe_facts(build(:recipe))).to eq []
    end

    it "speaks the current language" do
      recipe = build(:recipe, servings: 2, total_minutes: 120)

      I18n.with_locale(:"zh-CN") { expect(helper.recipe_facts(recipe)).to eq [ "2 人份", "共 2 小时" ] }
    end
  end
end
