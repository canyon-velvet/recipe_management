require "rails_helper"

RSpec.describe RecommendSpecialist do
  let(:user) { create(:user) }
  let(:specialist) { described_class.new(user) }
  let!(:dinner) { create(:tag, key: "dinner", kind: "meal") }
  let!(:spicy) { create(:tag, key: "spicy", kind: "flavor") }

  def recipe(name, ingredients: [], tags: [], **attributes)
    create(:recipe, user: user, name: name, tags: tags, **attributes).tap do |recipe|
      ingredients.each do |ingredient_name|
        ingredient = user.ingredients.find_by(name: ingredient_name) || create(:ingredient, user: user, name: ingredient_name)
        recipe.recipe_ingredients.create!(ingredient: ingredient, quantity: "2", unit: "pcs")
      end
    end
  end

  def search(**input) = specialist.run_tool("search_recipes", input)
  def names(result) = result[:recipes].pluck(:name)

  describe "search_recipes" do
    it "finds the user's recipes that match every filter given" do
      recipe("Mapo tofu", ingredients: %w[Tofu Chili], tags: [ dinner, spicy ], total_minutes: 30, servings: 4)
      recipe("Egg fried rice", ingredients: %w[Eggs Rice], tags: [ dinner ], total_minutes: 15, servings: 2)
      recipe("Slow beef stew", ingredients: %w[Beef], tags: [ dinner ], total_minutes: 180, servings: 6)
      create(:recipe, name: "Someone else's tofu", tags: [ dinner ])

      expect(names(search)).to contain_exactly("Mapo tofu", "Egg fried rice", "Slow beef stew")
      expect(names(search(tags: %w[dinner spicy]))).to eq [ "Mapo tofu" ]
      expect(names(search(ingredients: %w[egg]))).to eq [ "Egg fried rice" ]
      expect(names(search(ingredients: %w[egg tofu]))).to eq []
      expect(names(search(max_total_minutes: 30))).to contain_exactly("Mapo tofu", "Egg fried rice")
      expect(names(search(min_servings: 4))).to contain_exactly("Mapo tofu", "Slow beef stew")
      expect(names(search(name: "STEW"))).to eq [ "Slow beef stew" ]
    end

    it "never returns a recipe with an ingredient the user avoids" do
      recipe("Satay", ingredients: [ "Peanut butter" ])
      recipe("花生汤", ingredients: [ "花生" ])
      recipe("Omelette", ingredients: [ "Eggs" ])
      create(:preference, user: user, category: "avoid", value: "peanut")
      create(:preference, user: user, category: "avoid", value: "花生")

      expect(names(search)).to eq [ "Omelette" ]
    end

    it "returns each recipe's tags, time, servings and ingredients, and whether there were more" do
      found = recipe("Mapo tofu", ingredients: %w[Tofu], tags: [ spicy ], total_minutes: 30, servings: 4)
      stub_const("RecommendSpecialist::SEARCH_LIMIT", 1)

      expect(search).to eq(recipes: [ { id: found.id, name: "Mapo tofu", tags: [ "spicy" ], total_minutes: 30,
                                       servings: 4, ingredients: [ "Tofu" ] } ], more: false)

      recipe("Omelette")
      expect(search[:more]).to be true
    end
  end

  describe "get_recipe" do
    it "reads one of the user's recipes in full" do
      found = recipe("Mapo tofu", ingredients: %w[Tofu], tags: [ spicy ], description: "Numbing", prep_minutes: 10)

      expect(specialist.run_tool("get_recipe", { id: found.id })).to include(
        name: "Mapo tofu", description: "Numbing", tags: [ "spicy" ], prep_minutes: 10,
        ingredients: [ "2 pcs Tofu" ], steps: [ "Cook it." ]
      )
    end

    it "can't read another user's recipe" do
      other = create(:recipe)

      expect(specialist.run_tool("get_recipe", { id: other.id })).to eq(error: "There's no recipe with id #{other.id}.")
    end
  end

  describe "show_recipes" do
    it "keeps the user's recipes to show, in order and once each, and says which ids weren't found" do
      tofu = recipe("Mapo tofu")
      rice = recipe("Egg fried rice")
      other = create(:recipe)

      expect(specialist.run_tool("show_recipes", { ids: [ rice.id, other.id, tofu.id, rice.id ] }))
        .to eq(shown: [ rice.id, tofu.id ], not_found: [ other.id ])

      # Another call replaces the cards
      specialist.run_tool("show_recipes", { ids: [ tofu.id ] })
      expect(specialist.shown_recipe_ids).to eq [ tofu.id ]
    end
  end

  it "reports a bad call as an error instead of raising" do
    expect(specialist.run_tool("search_recipes", "{not json")).to eq(error: "The input isn't a JSON object.")
    expect(specialist.run_tool("delete_recipe", {})).to eq(error: "There's no tool called delete_recipe.")
  end

  it "tells Claude the user's preferences, the tags and their ingredients" do
    recipe("Mapo tofu", ingredients: %w[Tofu])
    create(:preference, user: user, category: "avoid", value: "peanut")
    create(:preference, user: user, category: "household", value: "2 adults")

    expect(specialist.system_prompt).to include(
      "- avoid: peanut\n- household: 2 adults", "dinner: Dinner\nspicy: Spicy", "Ingredients in the user's recipes: Tofu"
    )
    expect(described_class.new(create(:user)).system_prompt).to include("(none yet)")
    expect(specialist.tools.first.dig(:input_schema, :properties, :tags, :items, :enum)).to eq %w[dinner spicy]
  end
end
