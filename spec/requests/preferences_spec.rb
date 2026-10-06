require "rails_helper"

RSpec.describe "Preferences", type: :request do
  let(:user) { create(:user) }

  before { post login_path, params: { username: user.username, password: "password" } }

  it "lists the user's preferences under every category" do
    create(:preference, user: user, category: "avoid", value: "peanuts")
    create(:preference, user: create(:user), category: "avoid", value: "shellfish")

    get preferences_path

    expect(response.body).to include("Diet", "Likes", "Dislikes", "Avoid", "Household", "peanuts")
    expect(response.body).not_to include("shellfish")
  end

  it "adds a preference and returns just that category's card" do
    post preferences_path, params: { preference: { category: "likes", value: "spicy food" } }

    expect(user.preferences.likes.pluck(:value)).to eq [ "spicy food" ]
    expect(response.body).to include('id="preferences_likes"', "spicy food")
  end

  it "shows the error in the card when the preference is invalid" do
    create(:preference, user: user, category: "likes", value: "spicy food")

    post preferences_path, params: { preference: { category: "likes", value: "Spicy food" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Preference is already listed")
  end

  it "rejects an unknown category" do
    post preferences_path, params: { preference: { category: "mood", value: "happy" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(user.preferences).to be_empty
  end

  it "removes the user's own preference" do
    preference = create(:preference, user: user, category: "dislikes", value: "cilantro")

    delete preference_path(preference)

    expect(user.preferences).to be_empty
    expect(response.body).to include('id="preferences_dislikes"')
  end

  it "can't remove another user's preference" do
    other = create(:preference, user: create(:user), category: "avoid", value: "peanuts")

    delete preference_path(other)

    expect(response).to have_http_status(:not_found)
    expect(other.reload).to be_persisted
  end
end
