require "rails_helper"

RSpec.describe "Preferences", type: :system do
  let(:user) { create(:user) }

  it "adds and removes facts from the account menu's Preferences page" do
    log_in_as user
    find(".account-toggle").click
    click_link "Preferences"

    within("#preferences_avoid") do
      fill_in "Avoid", with: "peanuts"
      click_button "Add"
      expect(page).to have_css(".preference-chip", text: "peanuts")
      expect(page).to have_field("Avoid", with: "")
      # The keyboard stays in the box, ready for the next one
      expect(page).to have_css("#avoid_preference_value:focus")
    end

    within("#preferences_household") do
      fill_in "Household", with: "2 adults and a toddler"
      click_button "Add"
      expect(page).to have_css(".preference-chip", text: "2 adults and a toddler")
      # One household fact: the box hides until it's removed
      expect(page).to have_no_field("Household")

      click_button "Remove 2 adults and a toddler"
      expect(page).to have_no_css(".preference-chip")
      expect(page).to have_field("Household")
    end

    expect(user.preferences.pluck(:category, :value)).to eq [ [ "avoid", "peanuts" ] ]
  end
end
