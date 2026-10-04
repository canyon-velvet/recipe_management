# The import form: a recipe link, or the recipe's text pasted in. Starting an import puts a Draft in the
# Draft box; ImportRecipeJob reads it in the background.
class ImportsController < ApplicationController
  # Each import can cost a Claude call. Backed by Rails.cache (Redis), so the limit holds across processes.
  rate_limit to: 20, within: 1.hour, by: -> { current_user.id }, only: :create,
             with: -> { redirect_to new_import_path, alert: t("flash.import_rate_limited") }

  before_action :set_form, only: [ :new, :create ]

  def new
  end

  def create
    @result = StartImportService.new(user: current_user, url: @url, text: @text).call

    if @result.success?
      redirect_to drafts_path, notice: t("flash.import_started"), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_form
    @url = params[:url].to_s.strip
    @text = params[:text].to_s
    @paste = params[:paste].present? || @text.present?
    @can_paste = CleanRecipeService.available?
  end
end
