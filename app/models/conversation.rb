# A chat between a user and the assistant. The panel shows the user's newest one; "New chat" starts another.
class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, -> { order(:created_at, :id) }, dependent: :destroy, inverse_of: :conversation

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # Adds the user's message and the assistant's reply to it, which is pending until it's written.
  # Returns both; if the user's message is invalid, nothing is saved and the reply is nil.
  def ask(content)
    question = messages.new(role: :user, content: content)
    return [ question, nil ] unless question.valid?

    transaction do
      question.save!
      [ question, messages.create!(role: :assistant, status: :pending) ]
    end
  end

  # The newest messages, oldest first: what the panel shows and what the assistant reads, so a long chat costs the
  # same as a short one.
  def recent_messages(limit) = messages.reorder(created_at: :desc, id: :desc).limit(limit).reverse

  # The recent finished messages as Claude reads them: oldest first, starting with one of the user's (the API
  # requires that). Empty ones are left out: the API rejects empty text. A reply's recipe cards and their reasons are
  # noted after its text, so follow-ups such as "why the second one?" make sense.
  def context(limit)
    finished = recent_messages(limit).select(&:done?)
    names = user.recipes.where(id: finished.flat_map(&:recipe_ids)).pluck(:id, :name).to_h
    turns = finished.filter_map do |message|
      cards = message.recipe_ids.filter_map do |id|
        [ "#{names[id]} (id #{id})", message.card_reasons[id.to_s] ].compact.join(": ") if names[id]
      end
      note = "(Recipe cards shown: #{cards.join('; ')})" if cards.any?
      content = [ message.content.presence, note ].compact.join("\n\n")
      { role: message.role, content: content } if content.present?
    end
    turns.drop_while { |turn| turn[:role] == "assistant" }
  end

  # Who wrote the last finished reply, e.g. "recommend", so the router can keep follow-ups with it.
  def last_agent = messages.assistant.done.last&.agent
end
