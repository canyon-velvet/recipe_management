# Writes the assistant's pending reply (WriteReplyJob runs this in the background). The router (Haiku) reads the
# conversation so far and either answers itself or hands it to the Recommend specialist (Sonnet), which searches the
# user's recipes with its tools and picks some to show as cards. The answer streams into the user's open panel as it's
# written, then the reply is saved. Each attempt is recorded as a Run, and each model call and tool call in it as a
# Step. If Claude fails, the reply is marked failed so the panel shows an error instead of "Thinking…" forever.
class WriteReplyService
  ROUTER_MODEL = "claude-haiku-4-5"
  # Plenty for a chat answer; a reply that hits it is cut off rather than failing.
  MAX_TOKENS = 8_000
  # How much of the conversation Claude reads.
  CONTEXT_MESSAGES = 20
  # Tool calls a specialist may make for one reply. Past it, it's told to answer with what it has.
  MAX_TOOL_CALLS = 8
  # The panel is updated at most this often while the reply streams in.
  BROADCAST_INTERVAL = 0.15

  ROUTER_PROMPT = <<~PROMPT.freeze
    You are the assistant in a home recipe app. The user collects recipes, plans the week's meals, and gets a
    grocery list from the plan. Help with cooking: what to make, techniques, substitutions, timings, and how to use
    this app.

    Reply in the language of the user's latest message. Keep answers short and practical; use Markdown lists when
    they help.

    When the user wants recipes from their own collection (what to cook tonight, something with eggs, a quick dinner,
    a dish for guests), call transfer_to_recommend, without writing anything first: the Recommend specialist can
    search their saved recipes. You can't see them yourself, so never claim a recipe is in their collection.

    You can't take actions in the app yet, such as importing a recipe link, saving a recipe or changing a meal plan.
    Never say you did; point the user to the app instead (for a link, the Import recipe button on All Recipes).
  PROMPT
  # Added when the Recommend specialist wrote the last reply, so follow-ups stay with it.
  PINNED_PROMPT = <<~PROMPT.freeze
    The last reply in this chat came from the Recommend specialist. If the user's latest message follows up on it
    (for example "anything quicker?" or "how spicy is the second one?"), call transfer_to_recommend.
  PROMPT
  TRANSFER_TO_RECOMMEND = {
    name: "transfer_to_recommend",
    description: "Hand the conversation to the Recommend specialist, which searches the user's saved recipes and " \
                 "suggests some.",
    input_schema: { type: "object", properties: {} }
  }.freeze

  def initialize(reply, client: nil)
    @reply = reply
    @client = client
  end

  def call
    return unless @reply.pending?
    # A pending reply that already has a run was interrupted: Sidekiq re-queues a job it kills on shutdown, and the
    # kill skips the rescues below. Ending it as failed beats "Thinking…" forever; the user can ask again.
    if @reply.run
      @run = @reply.run
      @step = @run.steps.last
      return fail_reply("interrupted")
    end

    @run = @reply.create_run!(model: ROUTER_MODEL)
    @text = +""
    messages = [ route ]
    if transfer?(messages.first)
      @run.update!(model: RecommendSpecialist::MODEL)
      @reply.agent = :recommend
      # Anything the router wrote before handing over is dropped, and the panel goes back to "Thinking…".
      @text = +""
      broadcast(@reply.tap { _1.content = @text })
      messages = recommend
    else
      @reply.agent = :router
    end
    text = messages.map { |message| final_text(message) }.compact_blank.join("\n\n")

    if messages.last.stop_reason == :refusal
      @reply.recipe_ids = []
      finish(I18n.t("assistant.declined"))
      @run.fail!("refusal: #{messages.last.stop_details&.category}")
    elsif text.blank?
      # An empty reply would be sent back as history, which the API rejects, breaking the rest of the chat.
      fail_reply("empty reply")
    else
      finish(text)
      @run.succeed!
    end
  rescue Anthropic::Errors::APIError => e
    fail_reply(e)
  rescue StandardError => e
    # Anything unexpected still ends the reply, so the panel doesn't wait forever; the error is reported.
    Rails.error.report(e, handled: true, context: { message_id: @reply.id })
    fail_reply(e)
  end

  private

  def client = @client ||= Anthropic::Client.new(api_key: CleanRecipeService.api_key)

  def route
    stream_step("router", ROUTER_MODEL) do
      client.messages.stream(model: ROUTER_MODEL, max_tokens: MAX_TOKENS, system_: router_prompt,
                             messages: history, tools: [ TRANSFER_TO_RECOMMEND ])
    end
  end

  def router_prompt = last_reply&.recommend? ? "#{ROUTER_PROMPT}\n#{PINNED_PROMPT}" : ROUTER_PROMPT

  def transfer?(message)
    message.content.any? { |block| block.type == :tool_use && block.name == TRANSFER_TO_RECOMMEND[:name] }
  end

  # The Recommend specialist's turn: it calls tools until it has its answer. Each model call's response goes back
  # unchanged with the tools' results, as the API requires. Returns its messages, the last one being the answer.
  def recommend
    specialist = RecommendSpecialist.new(@reply.conversation.user)
    request = {
      model: RecommendSpecialist::MODEL, max_tokens: MAX_TOKENS, system_: specialist.system_prompt,
      tools: specialist.tools, output_config: { effort: :medium },
      # If the model declines, the API retries on a suitable fallback model within the same call.
      betas: [ "server-side-fallback-2026-07-01" ], fallbacks: :default
    }
    conversation = history
    tool_calls = 0
    responses = []

    loop do
      response = stream_step("recommend", RecommendSpecialist::MODEL) do
        client.beta.messages.stream(**request, messages: conversation)
      end
      responses << response
      tool_uses = response.content.select { |block| block.type == :tool_use }
      break if response.stop_reason != :tool_use || tool_uses.empty?
      # It was told it had reached the limit and still asks for more.
      raise "the Recommend specialist kept calling tools past the limit" if tool_calls > MAX_TOOL_CALLS

      results = tool_uses.map do |tool_use|
        tool_calls += 1
        run_tool(specialist, tool_use, over_limit: tool_calls > MAX_TOOL_CALLS)
      end
      conversation += [ { role: :assistant, content: response.content }, { role: :user, content: results } ]
    end

    @reply.recipe_ids = specialist.shown_recipe_ids
    responses
  end

  # Runs one of the specialist's tools, recorded as a step, and returns its result for Claude.
  def run_tool(specialist, tool_use, over_limit:)
    @step = @run.steps.create!(name: tool_use.name, input: tool_use.input)
    broadcast(@reply.tap { _1.content = @text }, activity: I18n.t("assistant.searching"))
    result =
      if over_limit
        { error: "You've used all #{MAX_TOOL_CALLS} tool calls for this reply. Answer with what you have." }
      else
        specialist.run_tool(tool_use.name, tool_use.input)
      end
    @step.finish!(result)
    { type: :tool_result, tool_use_id: tool_use.id, content: result.to_json, is_error: result.key?(:error) }
  end

  # One model call, recorded as a step: streams its text into the panel after what's been written so far, then
  # returns the complete message (content, stop reason, token usage).
  def stream_step(name, model)
    @step = @run.steps.create!(name: name, model: model)
    stream = yield
    separator = @text.present? ? "\n\n" : ""
    last_broadcast = 0
    stream.text.each do |delta|
      @text << separator << delta
      separator = ""
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      next if now - last_broadcast < BROADCAST_INTERVAL

      last_broadcast = now
      broadcast(@reply.tap { _1.content = @text })
    end
    stream.accumulated_message.tap { |message| @step.succeed!(message.usage) }
  end

  # A message's text. If the model declined part-way and a fallback model took over, only the fallback's answer
  # counts: the text before the last fallback block was abandoned.
  def final_text(message)
    blocks = message.content
    last_fallback = blocks.rindex { |block| block.type == :fallback }
    blocks.drop(last_fallback ? last_fallback + 1 : 0).select { |block| block.type == :text }.map(&:text).join
  end

  # The recent finished messages, oldest first, starting with one of the user's (the API requires that). Empty
  # ones are left out: the API rejects empty text. A reply's recipe cards are noted after its text, so follow-ups
  # such as "the second one" make sense.
  def history
    @history ||= begin
      messages = @reply.conversation.recent_messages(CONTEXT_MESSAGES + 1)
                       .select { |message| message.done? && message.content.present? }
                       .drop_while(&:assistant?)
      names = @reply.conversation.user.recipes.where(id: messages.flat_map(&:recipe_ids)).pluck(:id, :name).to_h
      messages.map do |message|
        cards = message.recipe_ids.filter_map { |id| "#{names[id]} (id #{id})" if names[id] }
        content = cards.any? ? "#{message.content}\n\n(Recipe cards shown: #{cards.join(', ')})" : message.content
        { role: message.role, content: content }
      end
    end
  end

  def last_reply
    @reply.conversation.messages.assistant.done.where.not(id: @reply.id).last
  end

  def finish(content)
    @reply.update!(content: content, status: :done)
    broadcast(@reply)
  end

  def fail_reply(error)
    message = error.is_a?(Exception) ? "#{error.class}: #{error.message}" : error
    @reply.update!(status: :failed)
    @step.fail!(message) if @step && !@step.finished?
    @run&.fail!(message)
    broadcast(@reply)
  end

  # Replaces the reply in the user's open panel (any page, any tab) with its latest state, and what the assistant is
  # doing while it isn't writing, such as searching recipes.
  def broadcast(reply, activity: nil)
    Turbo::StreamsChannel.broadcast_replace_to(
      [ reply.conversation.user, :assistant ], target: reply,
      partial: "assistant/messages/message", locals: { message: reply, activity: activity }
    )
  end
end
