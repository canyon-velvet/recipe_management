require "rails_helper"

# Imports real recipe pages end to end: nothing is stubbed. The page is fetched from the web, Claude cleans it up, and
# the import job runs in the background while the Draft box updates live. It costs a Claude call per example and
# depends on the sites being up, so it only runs when asked:
#
#   LIVE_IMPORT=1 bundle exec rspec spec/system/import_recipe_spec.rb
#
# Add RECORD_VIDEO=1 to also record the README demo. Everything it saves is rolled back with the test database.
RSpec.describe "Importing a recipe from a link", type: :system do
  let(:user) { create(:user, username: "home_cook") }

  before do
    skip "live import: set LIVE_IMPORT=1 to fetch real pages and call Claude" unless ENV["LIVE_IMPORT"]
    unless CleanRecipeService.available?
      raise "LIVE_IMPORT needs an Anthropic API key (Rails credentials or ANTHROPIC_API_KEY)"
    end
  end

  # Run the import job in the background in this process (the test env only records jobs), so the Draft box shows
  # Reading… and then updates live, as it does with Sidekiq.
  around do |example|
    queue_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :async
    example.run
  ensure
    ActiveJob::Base.queue_adapter = queue_adapter
  end

  it "reads a recipe page's structured recipe into a draft and saves it", video: "import_recipe" do
    import_and_save "https://www.yummytoddlerfood.com/apple-oatmeal-cake/"

    expect(page).to have_css("h1", text: /apple oatmeal cake/i)
  end

  it "reads a 下厨房 recipe from the page text" do
    import_and_save "https://www.xiachufang.com/recipe/107110062/"

    expect(user.recipes.sole.ingredients).to be_present
  end

  private

  def import_and_save(url)
    log_in_as user
    click_link "All Recipes"
    click_link "Import recipe"
    fill_in "Recipe link", with: url
    click_button "Import"

    expect(page).to have_text("Importing… the recipe will wait in your Draft box.")
    card = "#draft_#{user.drafts.sole.id}"
    # Fetching the page and Claude's cleanup take a while; the card turns Ready without a page reload.
    using_wait_time(120) { expect(page).to have_css("#{card} .draft-status--ready") }

    within(card) { click_link "Review" }
    expect(page).to have_css("h1", text: "Review draft")
    click_button "Create recipe"

    expect(page).to have_text("Recipe saved from your Draft box.")
    expect(user.drafts).to be_empty
  end
end
