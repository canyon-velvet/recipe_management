module DraftsHelper
  # The account menu shows these on every page, so they come from one grouped count, memoized per request.
  def draft_counts
    @draft_counts ||= current_user.drafts.group(:status).count
  end
end
