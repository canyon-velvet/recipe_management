require "rails_helper"

RSpec.describe ExtractRecipeService do
  def extract(**json_ld)
    recipe = { "@type" => "Recipe", "name" => "Apple cake", "recipeIngredient" => [ "1 apple" ],
               "recipeInstructions" => [ "Bake it." ] }.merge(json_ld.stringify_keys)
    html = %(<html><script type="application/ld+json">#{recipe.to_json}</script></html>)
    described_class.new(html, url: "https://example.com/apple-cake").call.recipe
  end

  describe "servings" do
    {
      "8" => 8,
      8 => 8,
      "4 servings" => 4,
      "Serves 4-6" => 4,
      "4 – 6 people" => 4,
      "4人份" => 4,
      [ "12", "12 servings" ] => 12,
      "1 loaf" => nil,
      "12 muffins" => nil,
      "0" => nil
    }.each do |yield_value, servings|
      it "reads #{yield_value.inspect} as #{servings.inspect}" do
        expect(extract(recipeYield: yield_value)[:servings]).to eq servings
      end
    end

    it "is nil without a yield" do
      expect(extract[:servings]).to be_nil
    end
  end

  describe "times" do
    it "converts ISO 8601 durations to minutes" do
      recipe = extract(prepTime: "PT15M", cookTime: "PT1H30M", totalTime: "P0DT1H45M")

      expect(recipe.values_at(:prep_minutes, :cook_minutes, :total_minutes)).to eq [ 15, 90, 105 ]
    end

    it "ignores missing, zero and unreadable times" do
      recipe = extract(prepTime: "PT0M", cookTime: "about an hour")

      expect(recipe.values_at(:prep_minutes, :cook_minutes, :total_minutes)).to eq [ nil, nil, nil ]
    end
  end
end
