# One message in a conversation: what the user asked, or the assistant's reply.
class Message < ApplicationRecord
  # Long enough for a recipe pasted in to import; the assistant only needs the last few messages' worth.
  MAX_LENGTH = 4_000
  # How many messages a user can send the assistant per day (UTC). Each costs a Claude call.
  DAILY_LIMIT = 50

  belongs_to :conversation
  has_one :run, dependent: :destroy

  enum :role, { user: "user", assistant: "assistant" }, validate: true
  enum :status, { pending: "pending", done: "done", failed: "failed" }, validate: true
  # Who wrote a reply: the router, or the specialist it handed the message to.
  enum :agent, { router: "router", recommend: "recommend" }, validate: { allow_nil: true }

  validates :content, presence: true, length: { maximum: MAX_LENGTH }, if: :user?

  attr_writer :recipes

  # Loads the cards of many messages in one query (the panel shows up to 50), instead of one query each.
  def self.load_recipes(messages, user)
    recipes = user.recipes.includes(:tags).where(id: messages.flat_map(&:recipe_ids)).index_by(&:id)
    messages.each { |message| message.recipes = recipes.values_at(*message.recipe_ids).compact }
  end

  # The recipes shown as cards under a reply, in the order shown. Ones deleted since are left out.
  def recipes
    return @recipes if @recipes
    return [] if recipe_ids.empty?

    conversation.user.recipes.includes(:tags).where(id: recipe_ids).sort_by { |recipe| recipe_ids.index(recipe.id) }
  end

  # Replaces the message in the user's open panel (any page, any tab) with its current state, and what the assistant
  # is doing while it isn't writing, such as searching recipes.
  def broadcast_update(activity: nil)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ conversation.user, :assistant ], target: self,
      partial: "assistant/messages/message", locals: { message: self, activity: activity }
    )
  end
end
