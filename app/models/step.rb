# One thing that happened while the assistant wrote a reply: a model call (its model, token usage and what it wrote)
# or a tool call (what it was given and returned). Each has its timing (created_at to finished_at) and any error.
# See Run.
class Step < ApplicationRecord
  belongs_to :run

  validates :name, presence: true

  # Ends a model call with its token usage and what it wrote.
  def succeed!(usage, output = nil)
    update!(input_tokens: usage.input_tokens, output_tokens: usage.output_tokens, output: output,
            finished_at: Time.current)
  end

  # Ends a tool call with what it returned.
  def finish!(output)
    update!(output: output, finished_at: Time.current)
  end

  def fail!(error)
    update!(error: error.to_s.truncate(255), finished_at: Time.current)
  end

  def finished? = finished_at.present?
end
