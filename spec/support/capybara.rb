# System specs run in Playwright's headless Chromium, set up once with
# `npm install && npx playwright install chromium`. Rails registers the :playwright driver itself.
RSpec.configure do |config|
  config.before(type: :system) { driven_by :playwright }
end
