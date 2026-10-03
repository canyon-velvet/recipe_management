module DraftsHelper
  # The account menu shows these on every page, so they come from one grouped count, memoized per request.
  def draft_counts
    @draft_counts ||= current_user.drafts.group(:status).count
  end

  def drafts_count = draft_counts.values.sum

  # Ready drafts can be reviewed and failed ones need a decision; drafts still reading need nothing yet.
  def drafts_need_attention? = draft_counts.values_at("ready", "failed").compact.sum.positive?
end
