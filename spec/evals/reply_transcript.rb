# Writes down everything that went into an assistant reply, as Markdown, for reading after a live eval: the chat
# before it, each model call (who made it, why it stopped, what it wrote) and tool call (what it was given and
# returned) of its run, then the saved reply with its cards and suggestions.
class ReplyTranscript
  # A tool's result is cut to this many characters: a search can return a lot.
  RESULT_LIMIT = 600

  def initialize(reply)
    @reply = reply
  end

  def to_s = [ chat, steps, outcome ].flatten.compact.join("\n\n")

  private

  def chat
    @reply.conversation.messages.where(id: ...@reply.id).map do |message|
      "**#{message.agent || message.role}:** #{message.content}"
    end
  end

  # A reply that failed before its run started has none.
  def steps
    agent = nil
    Array(@reply.run&.steps).flat_map do |step|
      next tool_call(step) unless step.model

      handoff = "→ handed over to **#{step.name}**" if agent && step.name != agent
      agent = step.name
      [ handoff, model_call(step) ].compact
    end
  end

  # A call that failed has no tokens or output, only its error.
  def model_call(step)
    output = step.output
    return "- **#{step.name}** (#{step.model})#{error(step)}" unless output

    line = "- **#{step.name}** (#{step.model}, #{step.input_tokens} in / #{step.output_tokens} out): " \
           "#{Array(output['blocks']).join(', ')}; stopped: #{output['stop_reason']}#{error(step)}"
    [ line, quote(output["text"]) ].compact.join("\n")
  end

  def tool_call(step)
    "- `#{step.name}` #{step.input.to_json} → #{step.output.to_json.truncate(RESULT_LIMIT)}#{error(step)}"
  end

  def outcome
    reply = [ "**Reply** (#{@reply.status}, by #{@reply.agent}):", quote(@reply.content) ].compact.join("\n")
    extras = @reply.recipes.map { |recipe| "- Card: #{recipe.name} — #{@reply.card_reason(recipe)}" }
    extras += @reply.preference_suggestions.map { |s| "- Suggested: #{s['category']}: #{s['value']}" }
    extras << "- Run error: #{@reply.run.error}" if @reply.run&.error
    [ reply, extras.join("\n").presence ]
  end

  def error(step) = (" — error: #{step.error}" if step.error)

  def quote(text) = text.presence&.lines&.map { |line| "> #{line}" }&.join
end
