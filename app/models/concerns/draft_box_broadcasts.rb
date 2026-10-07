# Keeps the user's open pages current while drafts are read in the background (Turbo Streams over Action Cable,
# on the user's own signed stream): the Draft box card and the draft's cards in the assistant's chat are replaced or
# removed, the account menu's count and dot are refreshed, and a toast says when a draft is ready to review (hidden
# while the chat is open, where the card shows it). Pages subscribe in the layout.
module DraftBoxBroadcasts
  extend ActiveSupport::Concern

  included do
    # One after_commit for the counts: Rails keeps only the last of after_create/update/destroy_commit that
    # names the same method.
    after_commit :broadcast_draft_counts
    after_update_commit :broadcast_card, :broadcast_chat_cards, :broadcast_ready_toast
    after_destroy_commit :broadcast_removal
  end

  private

  def draft_box_stream = [ user, :drafts ]

  def broadcast_card
    broadcast_replace_to draft_box_stream, target: self, partial: "drafts/draft", locals: { draft: self }
  end

  def broadcast_removal
    broadcast_remove_to draft_box_stream, target: self
    Turbo::StreamsChannel.broadcast_remove_to chat_stream, targets: chat_cards
  end

  # The draft's cards under the assistant's replies that imported it (one per reply, so they're found by class).
  def broadcast_chat_cards
    Turbo::StreamsChannel.broadcast_replace_to chat_stream, targets: chat_cards,
                                                            partial: "assistant/messages/draft_card",
                                                            locals: { draft: self }
  end

  def chat_stream = [ user, :assistant ]

  def chat_cards = ".assistant-draft-#{id}"

  # These partials aren't about one draft, so they go through the channel directly (a model broadcast would pass
  # the draft along as an extra local).
  def broadcast_draft_counts
    counts = user.drafts.group(:status).count
    Turbo::StreamsChannel.broadcast_replace_to draft_box_stream, target: "account_dot",
                                                                 partial: "drafts/attention_dot", locals: { counts: counts }
    Turbo::StreamsChannel.broadcast_replace_to draft_box_stream, target: "draft_box_count",
                                                                 partial: "drafts/menu_count", locals: { counts: counts }
  end

  def broadcast_ready_toast
    return unless saved_change_to_status? && ready?

    Turbo::StreamsChannel.broadcast_append_to draft_box_stream, target: "toasts", partial: "shared/toast", locals: {
      message: I18n.t("drafts.ready_toast", title: title),
      link_text: I18n.t("drafts.draft.review"),
      href: Rails.application.routes.url_helpers.new_recipe_path(draft_id: id)
    }
  end
end
