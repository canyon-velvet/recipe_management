require "rails_helper"

RSpec.describe WriteReplyService do
  let(:conversation) { create(:conversation) }
  let(:reply) { conversation.ask("What can I make with eggs?").last }

  def write(client) = described_class.new(reply, client: client).call

  it "streams the reply, saves it and records the run" do
    client = FakeClaude.new([ "Try ", "a **tomato ", "and egg** stir-fry." ])

    write(client)

    expect(reply.reload).to have_attributes(status: "done", content: "Try a **tomato and egg** stir-fry.")
    expect(reply.run).to have_attributes(status: "succeeded", model: "claude-sonnet-5-5", input_tokens: 120,
                                         output_tokens: 3, error: nil)
    expect(reply.run.finished_at).to be_present
  end

  it "sends the recent finished messages, starting with the user's, with low effort and refusal fallbacks" do
    earlier = conversation.ask("Hi").last
    earlier.update!(content: "Hello! What are we cooking?", status: :done)
    failed = conversation.ask("Anything?").last
    failed.update!(status: :failed)
    client = FakeClaude.new([ "Eggs!" ])

    write(client)

    request = client.requests.sole
    expect(request[:messages]).to eq [
      { role: "user", content: "Hi" },
      { role: "assistant", content: "Hello! What are we cooking?" },
      { role: "user", content: "Anything?" },
      { role: "user", content: "What can I make with eggs?" }
    ]
    expect(request).to include(model: "claude-sonnet-5-5", output_config: { effort: :low }, fallbacks: :default)
    expect(request[:system_]).to include("language of the user's latest message")
  end

  it "reads only the last messages of a long chat" do
    25.times { |i| conversation.messages.create!(role: :user, content: "Message #{i}") }
    client = FakeClaude.new([ "OK" ])

    write(client)

    messages = client.requests.sole[:messages]
    expect(messages.size).to be <= WriteReplyService::CONTEXT_MESSAGES
    expect(messages.last).to eq(role: "user", content: "What can I make with eggs?")
  end

  it "shows the reply in the user's open panel as it streams" do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    stub_const("WriteReplyService::BROADCAST_INTERVAL", 0)

    write(FakeClaude.new([ "Eggs ", "and ", "rice." ]))

    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
      .with([ conversation.user, :assistant ], hash_including(target: reply)).at_least(4).times
  end

  it "marks the reply failed, not Thinking… forever, when Claude errors part-way" do
    error = Anthropic::Errors::APIConnectionError.new(url: URI("https://api.anthropic.com/v1/messages"))

    write(FakeClaude.new([ "Try " ], error: error))

    expect(reply.reload.status).to eq "failed"
    expect(reply.run).to have_attributes(status: "failed", error: "Anthropic::Errors::APIConnectionError: Connection error.")
  end

  it "says it can't help when every model declines" do
    write(FakeClaude.new([], stop_reason: :refusal))

    expect(reply.reload).to have_attributes(status: "done", content: "Sorry, I can't help with that one.")
    expect(reply.run).to have_attributes(status: "failed", error: "refusal: cyber")
  end

  it "leaves a reply that's already written alone" do
    reply.update!(status: :done, content: "Done already")
    client = FakeClaude.new([ "Again" ])

    write(client)

    expect(client.requests).to be_empty
    expect(reply.reload.content).to eq "Done already"
  end
end
