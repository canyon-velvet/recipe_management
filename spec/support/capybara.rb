# System specs run in Playwright's headless Chromium, set up once with
# `npm install && npx playwright install chromium`. Rails registers the :playwright driver itself.
#
# `RECORD_VIDEO=1 bundle exec rspec spec/system` also records each spec tagged `video: "name"` to
# tmp/videos/name.webm. The folder is emptied first, so it only ever holds the latest run's videos.
VIDEO_DIR = Rails.root.join("tmp/videos")
SCREEN = { width: 1280, height: 800 }.freeze

RSpec.configure do |config|
  config.before(:suite) do
    if ENV["RECORD_VIDEO"]
      FileUtils.rm_rf(VIDEO_DIR)
      FileUtils.mkdir_p(VIDEO_DIR)
    end
  end

  config.before(type: :system) do |example|
    driven_by :playwright, screen_size: SCREEN.values, options: { record_video_size: SCREEN }

    # The driver outlives each spec, so a spec that doesn't record clears the last one's callback.
    video = example.metadata[:video]
    if ENV["RECORD_VIDEO"] && video
      page.driver.on_save_screenrecord { |path| FileUtils.mv(path, VIDEO_DIR.join("#{video}.webm")) }
    else
      page.driver.on_save_screenrecord
    end
  end

  # The test env turns CSRF protection off, which also drops the csrf-token meta tag that the app's JavaScript
  # sends with its fetch requests. Browser specs keep it on, as in the real app.
  config.around(type: :system) do |example|
    forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = forgery_protection
  end
end
