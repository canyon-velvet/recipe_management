module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&action)
    I18n.with_locale(saved_locale || browser_locale, &action)
  end

  def saved_locale
    session[:locale].presence_in(I18n.available_locales.map(&:to_s))
  end

  # Visitors whose browser prefers Chinese get Chinese; everyone else gets the default.
  def browser_locale
    request.headers["Accept-Language"].to_s.downcase.start_with?("zh") ? :"zh-CN" : I18n.default_locale
  end
end
