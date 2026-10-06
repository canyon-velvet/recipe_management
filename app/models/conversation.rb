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
end
