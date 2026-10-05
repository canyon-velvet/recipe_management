module SystemHelpers
  def log_in_as(user, password: "password")
    visit login_path
    fill_in "Username", with: user.username
    fill_in "Password", with: password
    click_button "Log in"
    expect(page).to have_text("Logged in.")
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
