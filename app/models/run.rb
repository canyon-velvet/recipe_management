# One attempt by the assistant to write a reply (see WriteReplyService): the model, how it went, and its token usage.
class Run < ApplicationRecord
  belongs_to :message

  enum :status, { running: "running", succeeded: "succeeded", failed: "failed" }, validate: true

  validates :model, presence: true

  def succeed!(usage)
    update!(status: :succeeded, input_tokens: usage.input_tokens, output_tokens: usage.output_tokens,
            finished_at: Time.current)
  end

  def fail!(error)
    update!(status: :failed, error: error.to_s.truncate(255), finished_at: Time.current)
  end
end
