# Stands in for Anthropic::Client in specs, so no real Claude calls are made. client.beta.messages.stream(**params)
# records the request and returns a stream that yields the given text pieces (optionally slowly, or raising part-way),
# then reports the finished message like the SDK's MessageStream: stop reason, content blocks, model and token usage.
#
# fallback_at: n simulates a server-side fallback: the first n pieces came from the model that declined part-way, the
# rest from fallback_model, with a fallback block between them.
class FakeClaude
  Usage = Data.define(:input_tokens, :output_tokens)
  StopDetails = Data.define(:category)
  Block = Data.define(:type, :text)
  Reply = Data.define(:stop_reason, :stop_details, :usage, :model, :content)

  attr_reader :requests

  def initialize(deltas = [], stop_reason: :end_turn, error: nil, delay: 0, fallback_at: nil,
                 fallback_model: "claude-opus-5-5")
    @deltas = deltas
    @stop_reason = stop_reason
    @error = error
    @delay = delay
    @fallback_at = fallback_at
    @fallback_model = fallback_model
    @requests = []
  end

  def beta = self
  def messages = self

  def stream(**params)
    @requests << params
    self
  end

  def text
    Enumerator.new do |yielder|
      @deltas.each do |delta|
        sleep @delay
        yielder << delta
      end
      raise @error if @error
    end
  end

  def accumulated_message
    stop_details = StopDetails.new(category: :cyber) if @stop_reason == :refusal
    Reply.new(stop_reason: @stop_reason, stop_details: stop_details,
              usage: Usage.new(input_tokens: 120, output_tokens: @deltas.size), model: model, content: content)
  end

  private

  def model = @fallback_at ? @fallback_model : @requests.last&.fetch(:model)

  def content
    return [ Block.new(type: :text, text: @deltas.join) ] unless @fallback_at

    [ Block.new(type: :text, text: @deltas.first(@fallback_at).join), Block.new(type: :fallback, text: nil),
      Block.new(type: :text, text: @deltas.drop(@fallback_at).join) ]
  end
end
