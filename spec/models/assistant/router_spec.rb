require "rails_helper"

RSpec.describe Assistant::Router do
  let(:user) { create(:user) }

  def response(*tool_names)
    FakeClaude::Reply.new(stop_reason: :tool_use, stop_details: nil, usage: nil,
                          content: tool_names.map { FakeClaude::ToolUse.new(type: :tool_use, id: "toolu_1", name: _1, input: {}) })
  end

  it "runs on Haiku with a transfer tool for each specialist" do
    router = described_class.new(user)

    expect(router.request).to include(model: "claude-haiku-4-5", max_tokens: 8_000)
    expect(router.request[:tools]).to eq [
      { name: "transfer_to_recommend",
        description: "Hand the conversation to the Recommend specialist, which searches the user's saved recipes " \
                     "and suggests some. Use it when they want recipes from their own collection: what to cook " \
                     "tonight, something with eggs, a quick dinner, a dish for guests.",
        input_schema: { type: "object", properties: {} } }
    ]
    expect(router.system_prompt).to include("language of the user's latest message", "can't take actions in the app yet")
  end

  it "keeps follow-ups with the specialist that wrote the last reply" do
    expect(described_class.new(user, last_agent: "recommend").system_prompt)
      .to include("The last reply in this chat came from the Recommend specialist", "call transfer_to_recommend.")
    expect(described_class.new(user, last_agent: "router").system_prompt).not_to include("The last reply")
    expect(described_class.new(user).system_prompt).not_to include("The last reply")
  end

  it "tells which specialist a response hands the conversation to" do
    router = described_class.new(user)

    expect(router.handoff(response("transfer_to_recommend"))).to eq Assistant::RecommendSpecialist
    expect(router.handoff(response)).to be_nil
    expect(router.handoff(response("search_recipes"))).to be_nil
  end
end
