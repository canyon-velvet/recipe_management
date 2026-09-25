class ApplicationController < ActionController::Base
  include Pagy::Method
  include Localization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  # Starts a fresh session to prevent session fixation, keeping the chosen language.
  def log_in(user)
    locale = session[:locale]
    reset_session
    session[:locale] = locale
    session[:user_id] = user.id
  end

  def authenticate_user!
    redirect_to login_path, alert: t("flash.login_required") unless logged_in?
  end

  def require_admin
    redirect_to root_path, alert: t("flash.admin_required") unless current_user&.admin?
  end
end
