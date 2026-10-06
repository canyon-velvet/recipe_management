# One attempt by the assistant to write a reply (see WriteReplyService): the model that wrote it, how it went, and its
# token usage. Its steps record each model call and tool call that went into it.
class Run < ApplicationRecord
  belongs_to :message
  has_many :steps, -> { order(:created_at, :id) }, dependent: :destroy, inverse_of: :run

  enum :status, { running: "running", succeeded: "succeeded", failed: "failed" }, validate: true

  validates :model, presence: true

  # The run's token usage is its model calls' together.
  def succeed!
    update!(status: :succeeded, input_tokens: steps.sum(:input_tokens), output_tokens: steps.sum(:output_tokens),
            finished_at: Time.current)
  end

  # Also fails the step that was under way, if any.
  def fail!(error)
    steps.where(finished_at: nil).each { |step| step.fail!(error) }
    update!(status: :failed, error: error.to_s.truncate(255), finished_at: Time.current)
  end
end
