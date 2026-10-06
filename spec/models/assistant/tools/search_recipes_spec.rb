require "rails_helper"

RSpec.describe Assistant::Tools::SearchRecipes do
  let(:user) { create(:user) }
  let(:turn) { Assistant::Turn.new }
  let(:tool) { described_class.new(user, turn) }
  let!(:dinner) { create(:tag, key: "dinner", kind: "meal") }
  let!(:spicy) { create(:tag, key: "spicy", kind: "flavor") }

  def recipe(name, ingredients: [], **attributes)
    create(:recipe, user: user, name: name, **attributes).tap do |recipe|
      ingredients.each do |ingredient|
        recipe.recipe_ingredients.create!(ingredient: create(:ingredient, user: user, name: ingredient))
      end
    end
  end

  def names(**input) = tool.call(input)[:recipes].pluck(:name)

  it "finds the user's recipes that match every filter given" do
    recipe("Mapo tofu", ingredients: %w[Tofu Chili], tags: [ dinner, spicy ], total_minutes: 30, servings: 4)
    recipe("Egg fried rice", ingredients: %w[Eggs Rice], tags: [ dinner ], total_minutes: 15, servings: 2)
    recipe("Slow beef stew", ingredients: %w[Beef], tags: [ dinner ], total_minutes: 180, servings: 6)
    create(:recipe, name: "Someone else's tofu", tags: [ dinner ])

    expect(names).to contain_exactly("Mapo tofu", "Egg fried rice", "Slow beef stew")
    expect(names(tags: %w[dinner spicy])).to eq [ "Mapo tofu" ]
    expect(names(ingredients: %w[egg])).to eq [ "Egg fried rice" ]
    expect(names(ingredients: %w[egg tofu])).to eq []
    expect(names(max_total_minutes: 30)).to contain_exactly("Mapo tofu", "Egg fried rice")
    expect(names(min_servings: 4)).to contain_exactly("Mapo tofu", "Slow beef stew")
    expect(names(name: "STEW")).to eq [ "Slow beef stew" ]
  end

  it "still returns recipes with an ingredient the user avoids, flagging the avoided items" do
    recipe("Satay", ingredients: [ "Peanut butter", "Chicken" ])
    recipe("花生汤", ingredients: [ "花生" ])
    recipe("Omelette", ingredients: [ "Eggs" ])
    create(:preference, user: user, category: "avoid", value: "peanut")
    create(:preference, user: user, category: "avoid", value: "花生")

    expect(tool.call({})[:recipes].to_h { [ _1[:name], _1[:avoided] ] })
      .to eq("Satay" => [ "peanut" ], "花生汤" => [ "花生" ], "Omelette" => nil)
  end

  it "notes the recipes it returned, so they can be shown as cards" do
    found = recipe("Mapo tofu")
    other = recipe("Omelette")

    tool.call({ name: "tofu" })

    expect(turn.found?(found.id)).to be true
    expect(turn.found?(other.id)).to be false
  end

  it "returns each recipe's tags, time, servings and ingredients, and whether there were more" do
    found = recipe("Mapo tofu", ingredients: %w[Tofu], tags: [ spicy ], total_minutes: 30, servings: 4)
    stub_const("Assistant::Tools::SearchRecipes::LIMIT", 1)

    expect(tool.call({})).to eq(recipes: [ { id: found.id, name: "Mapo tofu", tags: [ "spicy" ], total_minutes: 30,
                                             servings: 4, ingredients: [ "Tofu" ] } ], more: false)

    recipe("Omelette")
    expect(tool.call({})[:more]).to be true
  end

  it "offers the tags as the choices, and says so while it runs" do
    expect(tool.definition.dig(:input_schema, :properties, :tags, :items, :enum)).to eq %w[dinner spicy]
    expect(tool.activity).to eq "Searching your recipes…"
  end

  it "reports input that isn't an object as an error instead of raising" do
    expect(tool.call("{not json")).to eq(error: "The input isn't a JSON object.")
  end
end
