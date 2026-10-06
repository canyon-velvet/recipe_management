# Stands in for Anthropic::Client in specs, so no real Claude calls are made. client.messages.stream(**params) (or
# client.beta.messages.stream) records the request and returns a stream that yields the given text pieces (optionally
# slowly, or raising part-way), then reports the finished message like the SDK's MessageStream: stop reason, content
# blocks (text, then any tool calls) and token usage.
#
# A reply that takes several model calls scripts one per call with and_then:
#   FakeClaude.new(tool_uses: [ { name: "transfer_to_recommend", input: {} } ]).and_then([ "Try this." ])
class FakeClaude
  Usage = Data.define(:input_tokens, :output_tokens)
  StopDetails = Data.define(:category)
  Block = Data.define(:type, :text)
  ToolUse = Data.define(:type, :id, :name, :input)
  Reply = Data.define(:stop_reason, :stop_details, :usage, :content)
  Call = Data.define(:deltas, :tool_uses, :stop_reason, :error, :delay)

  attr_reader :requests

  def initialize(...)
    @calls = []
    @requests = []
    and_then(...)
  end

  def and_then(deltas = [], tool_uses: [], stop_reason: nil, error: nil, delay: 0)
    stop_reason ||= tool_uses.any? ? :tool_use : :end_turn
    @calls << Call.new(deltas:, tool_uses:, stop_reason:, error:, delay:)
    self
  end

  def messages = self
  def beta = self

  def stream(**params)
    @requests << params
    @call = @calls.fetch(@requests.size - 1) { raise "FakeClaude got more calls than it was given replies for" }
    self
  end

  def text
    Enumerator.new do |yielder|
      @call.deltas.each do |delta|
        sleep @call.delay
        yielder << delta
      end
      raise @call.error if @call.error
    end
  end

  def accumulated_message
    stop_details = StopDetails.new(category: :cyber) if @call.stop_reason == :refusal
    text = @call.deltas.any? ? [ Block.new(type: :text, text: @call.deltas.join) ] : []
    tool_uses = @call.tool_uses.map.with_index do |tool_use, i|
      ToolUse.new(type: :tool_use, id: "toolu_#{@requests.size}_#{i}", **tool_use)
    end
    Reply.new(stop_reason: @call.stop_reason, stop_details: stop_details,
              usage: Usage.new(input_tokens: 120, output_tokens: @call.deltas.size), content: text + tool_uses)
  end
end
