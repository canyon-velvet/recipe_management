# Writes the assistant's pending reply (WriteReplyJob runs this in the background): sends the conversation so far to
# Claude, streams the answer into the user's open panel as it's written, then saves it. Each attempt is recorded as a
# Run with its token usage. If Claude fails, the reply is marked failed so the panel shows an error instead of
# "Thinking…" forever.
class WriteReplyService
  MODEL = "claude-sonnet-5-5"
  # Plenty for a chat answer; a reply that hits it is cut off rather than failing.
  MAX_TOKENS = 8_000
  # How much of the conversation Claude reads.
  CONTEXT_MESSAGES = 20
  # The panel is updated at most this often while the reply streams in.
  BROADCAST_INTERVAL = 0.15

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are the assistant in a home recipe app. The user collects recipes, plans the week's meals, and gets a
    grocery list from the plan. Help with cooking: what to make, techniques, substitutions, timings, and how to use
    this app.

    Reply in the language of the user's latest message. Keep answers short and practical; use Markdown lists when
    they help.

    You can't see the user's saved recipes, meal plans or grocery lists yet. Never claim a recipe is in their
    collection; you can suggest dishes in general and say that searching their own recipes is coming soon.
  PROMPT

  def initialize(reply, client: nil)
    @reply = reply
    @client = client
  end

  def call
    # A job delivered twice (e.g. re-queued on a Sidekiq restart) leaves a reply that's written or being written alone.
    return unless @reply.pending? && @reply.run.nil?

    run = @reply.create_run!(model: MODEL)
    message = stream_reply
    # A fallback model may have answered instead; record which one did.
    run.update!(model: message.model.to_s) if message.model.present?
    text = final_text(message)

    if message.stop_reason == :refusal
      finish(I18n.t("assistant.declined"))
      run.fail!("refusal: #{message.stop_details&.category}")
    elsif text.blank?
      # An empty reply would be sent back as history, which the API rejects, breaking the rest of the chat.
      fail_reply(run, "empty reply")
    else
      finish(text)
      run.succeed!(message.usage)
    end
  rescue Anthropic::Errors::APIError => e
    fail_reply(run, e)
  rescue StandardError => e
    # Anything unexpected still ends the reply, so the panel doesn't wait forever; the error is reported.
    Rails.error.report(e, handled: true, context: { message_id: @reply.id })
    fail_reply(run, e)
  end

  private

  def client = @client ||= Anthropic::Client.new(api_key: CleanRecipeService.api_key)

  # Streams the reply into the panel, then returns the complete message (stop reason, token usage).
  def stream_reply
    @text = +""
    last_broadcast = 0
    stream = client.beta.messages.stream(
      model: MODEL, max_tokens: MAX_TOKENS, system_: SYSTEM_PROMPT, messages: history,
      output_config: { effort: :low },
      # If the model declines, the API retries on a suitable fallback model within the same call.
      betas: [ "server-side-fallback-2026-07-01" ], fallbacks: :default
    )
    stream.text.each do |delta|
      @text << delta
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      next if now - last_broadcast < BROADCAST_INTERVAL

      last_broadcast = now
      broadcast(@reply.tap { _1.content = @text })
    end
    stream.accumulated_message
  end

  # The reply's text. If the model declined part-way and a fallback model took over, only the fallback's answer
  # counts: the text before the last fallback block was abandoned.
  def final_text(message)
    blocks = message.content
    last_fallback = blocks.rindex { |block| block.type == :fallback }
    blocks.drop(last_fallback ? last_fallback + 1 : 0).select { |block| block.type == :text }.map(&:text).join
  end

  # The recent finished messages, oldest first, starting with one of the user's (the API requires that). Empty
  # ones are left out: the API rejects empty text.
  def history
    messages = @reply.conversation.recent_messages(CONTEXT_MESSAGES + 1)
                     .select { |message| message.done? && message.content.present? }
    messages = messages.drop_while(&:assistant?)
    messages.map { |message| { role: message.role, content: message.content } }
  end

  def finish(content)
    @reply.update!(content: content, status: :done)
    broadcast(@reply)
  end

  def fail_reply(run, error)
    @reply.update!(status: :failed)
    run&.fail!(error.is_a?(Exception) ? "#{error.class}: #{error.message}" : error)
    broadcast(@reply)
  end

  # Replaces the reply in the user's open panel (any page, any tab) with its latest state.
  def broadcast(reply)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ reply.conversation.user, :assistant ], target: reply,
      partial: "assistant/messages/message", locals: { message: reply }
    )
  end
end
