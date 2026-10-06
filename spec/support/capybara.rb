# System specs run in Playwright's headless Chromium, set up once with
# `npm install && npx playwright install chromium`. Rails registers the :playwright driver itself.
#
# `RECORD_VIDEO=1 bundle exec rspec spec/system` also records each spec tagged `video: "name"` to
# tmp/videos/name.webm, replacing that spec's last recording. Other specs' videos are kept.
# Find fields and buttons by their aria-label too, the name a screen reader announces.
Capybara.enable_aria_label = true

RSpec.configure do |config|
  video_dir = Rails.root.join("tmp/videos")
  screen = { width: 1280, height: 800 }

  config.before(:suite) do
    FileUtils.mkdir_p(video_dir) if ENV["RECORD_VIDEO"]
  end

  config.before(type: :system) do |example|
    # English regardless of the machine's language, which the app would otherwise pick up from Accept-Language.
    # When recording, each browser action waits a moment first, so the video is slow enough to follow.
    slow_mo = 1000 if ENV["RECORD_VIDEO"]
    driven_by :playwright, screen_size: screen.values,
                           options: { locale: "en-US", record_video_size: screen, slowMo: slow_mo }

    # The driver outlives each spec, so a spec that doesn't record clears the last one's callback.
    video = example.metadata[:video]
    if ENV["RECORD_VIDEO"] && video
      page.driver.on_save_screenrecord { |path| FileUtils.mv(path, video_dir.join("#{video}.webm")) }
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
