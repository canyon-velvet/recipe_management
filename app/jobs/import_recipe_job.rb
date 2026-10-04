# Reads an imported recipe into its Draft in the background (Sidekiq), so the user never waits on a page or Claude.
class ImportRecipeJob < ApplicationJob
  queue_as :default

  # Claude rate limits and outages are worth waiting out; after the last attempt the draft shows the failure.
  retry_on CleanRecipeService::TemporaryError, wait: :polynomially_longer, attempts: 5 do |job, _error|
    job.arguments.first.update!(status: :failed, failure_reason: :cleanup_failed)
  end

  # The draft was discarded before it was read.
  discard_on ActiveJob::DeserializationError

  def perform(draft)
    ImportRecipeService.new(draft).call
  end
end
