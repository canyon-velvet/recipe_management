# One message in a conversation: what the user asked, or the assistant's reply.
class Message < ApplicationRecord
  # Long enough for a recipe pasted in to import; the assistant only needs the last few messages' worth.
  MAX_LENGTH = 4_000

  belongs_to :conversation

  enum :role, { user: "user", assistant: "assistant" }, validate: true
  enum :status, { pending: "pending", done: "done", failed: "failed" }, validate: true

  validates :content, presence: true, length: { maximum: MAX_LENGTH }, if: :user?
end
