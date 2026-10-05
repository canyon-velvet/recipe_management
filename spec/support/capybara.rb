# System specs run in Playwright's headless Chromium (installed with `npx playwright install chromium`)
Capybara.register_driver(:playwright) do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true)
end

RSpec.configure do |config|
  config.before(type: :system) { driven_by :playwright }
end
