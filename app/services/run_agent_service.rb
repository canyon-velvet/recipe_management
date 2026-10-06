# Runs one of the assistant's agents (see Assistant::Agent) for a reply. It sends the conversation to the agent's
# model and streams the text into the user's open panel. It runs the tools the model calls and sends their results
# back, until the model answers or hands off to another agent. Each model call and tool call is recorded as a Step of
# the run.
#
# Returns the model's responses, the last being its answer (or its hand-off).
class RunAgentService
  # Tool calls an agent may make for one reply. Past it, it's told to answer with what it has.
  MAX_TOOL_CALLS = 8
  # The panel is updated at most this often while the text streams in.
  BROADCAST_INTERVAL = 0.15

  def initialize(agent, reply:, run:, context:, client:)
    @agent = agent
    @reply = reply
    @run = run
    @context = context
    @client = client
  end

  def call
    request = @agent.request # built once: the tools must stay the same for the whole turn
    messages = @context
    @text = +""
    tool_calls = 0
    responses = []

    loop do
      response = stream_step { @client.beta.messages.stream(**request, messages: messages) }
      responses << response
      tool_uses = response.content.select { |block| block.type == :tool_use }
      return responses if response.stop_reason != :tool_use || tool_uses.empty? || handoff?(tool_uses)
      # It was told it had reached the limit and still asks for more.
      raise "#{@agent.name} kept calling tools past the limit" if tool_calls > MAX_TOOL_CALLS

      results = tool_uses.map do |tool_use|
        tool_calls += 1
        run_tool(tool_use, over_limit: tool_calls > MAX_TOOL_CALLS)
      end
      # The model's response goes back unchanged, then the tools' results, as the API requires.
      messages += [ { role: :assistant, content: response.content }, { role: :user, content: results } ]
    end
  end

  private

  def handoff?(tool_uses) = tool_uses.any? { |tool_use| @agent.tool(tool_use.name)&.handoff? }

  # One model call, recorded as a step: streams its text into the panel after what the agent has written so far,
  # then returns the complete message (content, stop reason, token usage).
  def stream_step
    step = @run.steps.create!(name: @agent.name, model: @agent.model)
    stream = yield
    separator = @text.present? ? "\n\n" : ""
    last_broadcast = 0
    stream.text.each do |delta|
      @text << separator << delta
      separator = ""
      now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      next if now - last_broadcast < BROADCAST_INTERVAL

      last_broadcast = now
      @reply.tap { _1.content = @text }.broadcast_to_panel
    end
    stream.accumulated_message.tap { |message| step.succeed!(message.usage, summary(message)) }
  end

  # What a model call wrote, kept on its step for looking into a reply later: its kinds of blocks (thinking, text,
  # tool calls), its text and why it stopped.
  def summary(message)
    { stop_reason: message.stop_reason, blocks: message.content.map(&:type),
      text: message.content.select { |block| block.type == :text }.map(&:text).join }
  end

  # Runs one tool call, recorded as a step, and returns its result for the model.
  def run_tool(tool_use, over_limit:)
    tool = @agent.tool(tool_use.name)
    step = @run.steps.create!(name: tool_use.name, input: tool_use.input)
    @reply.tap { _1.content = @text }.broadcast_to_panel(activity: tool&.activity)
    result =
      if over_limit
        { error: "You've used all #{MAX_TOOL_CALLS} tool calls for this reply. Answer with what you have." }
      elsif tool
        tool.call(tool_use.input)
      else
        { error: "There's no tool called #{tool_use.name}." }
      end
    step.finish!(result)
    { type: :tool_result, tool_use_id: tool_use.id, content: result.to_json, is_error: result.key?(:error) }
  end
end
