class DraftsController < ApplicationController
  def index
    @drafts = current_user.drafts.newest_first
  end

  def destroy
    current_user.drafts.find(params[:id]).destroy
    redirect_to drafts_path, notice: t("flash.draft_discarded"), status: :see_other
  end
end
