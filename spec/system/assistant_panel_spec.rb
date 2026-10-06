require "rails_helper"

RSpec.describe "Assistant panel", type: :system do
  let(:user) { create(:user) }

  before { allow(CleanRecipeService).to receive(:available?).and_return(true) }

  it "opens beside the page, keeps the chat across pages and visits, and starts a new chat" do
    log_in_as user
    click_button "Open assistant"

    within("#assistant-panel") do
      expect(page).to have_text("Ask me what to cook tonight")
      fill_in "Ask about recipes…", with: "Dinner for 4?"
      find_field("Ask about recipes…").send_keys(:enter)

      expect(page).to have_css(".assistant-message--user", text: "Dinner for 4?")
      expect(page).to have_css(".assistant-message--assistant", text: "Thinking…")
      expect(page).to have_no_text("Ask me what to cook tonight")
      expect(page).to have_field("Ask about recipes…", with: "")
    end
    expect(page).to have_css("body.assistant-open")

    # Moving to another page keeps the panel and the chat
    click_link "All Recipes"
    expect(page).to have_css("#assistant-panel", text: "Dinner for 4?")
    expect(page).to have_css("body.assistant-open")

    # So does a full reload: the cookie brings it back open
    visit meal_plans_path
    expect(page).to have_css("#assistant-panel", text: "Dinner for 4?")

    within("#assistant-panel") do
      click_button "New chat"
      expect(page).to have_text("Ask me what to cook tonight")
      expect(page).to have_no_text("Dinner for 4?")
      click_button "Close assistant"
    end
    expect(page).to have_no_css("#assistant-panel")
    expect(page).to have_no_css("body.assistant-open")
  end

  it "sends on Enter but adds a line on Shift+Enter" do
    log_in_as user
    click_button "Open assistant"

    field = find_field("Ask about recipes…")
    field.send_keys("Eggs", %i[shift enter], "tomatoes")
    expect(user.conversations).to be_empty

    field.send_keys(:enter)
    expect(page).to have_css(".assistant-message--user", text: "Eggs\ntomatoes")
  end
end
