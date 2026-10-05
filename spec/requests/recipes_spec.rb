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

    expect(user.recipes.sole.attributes.values_at(*Draft::COUNT_KEYS)).to eq [ 4, 15, 30, 45 ]
    follow_redirect!
    expect(response.body).to include("Serves 4", "Prep 15 min", "Cook 30 min", "Total 45 min")
  end
end
