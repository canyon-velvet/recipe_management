require "rails_helper"

RSpec.describe "Recipes", type: :request do
  let(:user) { create(:user) }

  before { post login_path, params: { username: user.username, password: "password" } }

  it "saves servings and times from the form, filling the total from prep and cook" do
    post recipes_path, params: { recipe: {
      name: "Apple cake", source_id: create(:source, user: user).id,
      servings: "4", prep_minutes: "15", cook_minutes: "30", total_minutes: "",
      steps_attributes: { "0" => { body: "Bake it.", position: "1" } }
    } }

    recipe = user.recipes.sole
    expect([ recipe.servings, recipe.prep_minutes, recipe.cook_minutes, recipe.total_minutes ]).to eq [ 4, 15, 30, 45 ]
    follow_redirect!
    facts = Nokogiri::HTML(response.body).css(".recipe-facts > div").map { |fact| fact.css("dt, dd").map(&:text) }
    expect(facts).to eq [ [ "Servings", "4" ], [ "Prep", "15 min" ], [ "Cook", "30 min" ], [ "Total", "45 min" ] ]
  end

  it "shows a validation error, not a crash, for a number too large to save" do
    post recipes_path, params: { recipe: {
      name: "Apple cake", source_id: create(:source, user: user).id, prep_minutes: "9999999999",
      steps_attributes: { "0" => { body: "Bake it.", position: "1" } }
    } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(user.recipes).to be_empty
  end
end
