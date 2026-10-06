# Stands in for Anthropic::Client in specs, so no real Claude calls are made. client.beta.messages.stream(**params)
# records the request and returns a stream that yields the given text pieces (optionally slowly, or raising part-way),
# then reports the stop reason and token usage like the SDK's MessageStream.
class FakeClaude
  Usage = Data.define(:input_tokens, :output_tokens)
  StopDetails = Data.define(:category)
  Reply = Data.define(:stop_reason, :stop_details, :usage)

  attr_reader :requests

  def initialize(deltas = [], stop_reason: :end_turn, error: nil, delay: 0)
    @deltas = deltas
    @stop_reason = stop_reason
    @error = error
    @delay = delay
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
    stop_details = StopDetails.new(category: "cyber") if @stop_reason == :refusal
    Reply.new(stop_reason: @stop_reason, stop_details: stop_details,
              usage: Usage.new(input_tokens: 120, output_tokens: @deltas.size))
  end
end
