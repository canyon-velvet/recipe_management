require "rails_helper"

RSpec.describe RunAgentService do
  let(:conversation) { create(:conversation) }
  let(:user) { conversation.user }
  let(:reply) { conversation.ask("Something with tofu?").last }
  let(:run) { reply.create_run!(model: "claude-sonnet-5-5") }
  let(:agent) { Assistant::RecommendSpecialist.new(user) }
  let(:context) { [ { role: "user", content: "Something with tofu?" } ] }
  let!(:tofu) { create(:recipe, user: user, name: "Mapo tofu") }

  def run_agent(client, agent: self.agent)
    described_class.new(agent, reply: reply, run: run, context: context, client: client).call
  end

  it "runs the tools the model calls and sends back its response and their results, until it answers" do
    client = FakeClaude.new([ "Let me look." ], tool_uses: [ { name: "get_recipe", input: { id: tofu.id } } ])
                       .and_then([ "It's numbing." ])

    responses = run_agent(client)

    expect(responses.map(&:stop_reason)).to eq %i[tool_use end_turn]
    first, second = client.requests
    expect(first).to include(agent.request.merge(messages: context))
    tool_call, results = second[:messages].last(2)
    expect(tool_call).to eq(role: :assistant, content: responses.first.content)
    result = results[:content].sole
    expect(result).to include(type: :tool_result, tool_use_id: responses.first.content.last.id, is_error: false)
    expect(JSON.parse(result[:content])).to include("name" => "Mapo tofu", "steps" => [ "Cook it." ])
  end

  it "records each model call and tool call as a step" do
    client = FakeClaude.new(tool_uses: [ { name: "search_recipes", input: { name: "tofu" } } ]).and_then([ "Tofu!" ])

    run_agent(client)

    expect(run.steps.map { [ _1.name, _1.model, _1.input_tokens ] }).to eq [
      [ "recommend", "claude-sonnet-5-5", 120 ], [ "search_recipes", nil, nil ], [ "recommend", "claude-sonnet-5-5", 120 ]
    ]
    expect(run.steps.second).to have_attributes(input: { "name" => "tofu" }, finished_at: be_present)
    expect(run.steps.second.output["recipes"].sole).to include("id" => tofu.id, "name" => "Mapo tofu")
  end

  it "streams the text into the panel, and shows what it's doing while a tool runs" do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    stub_const("RunAgentService::BROADCAST_INTERVAL", 0)
    client = FakeClaude.new([ "Looking." ], tool_uses: [ { name: "search_recipes", input: {} } ]).and_then([ "None." ])

    run_agent(client)

    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to)
      .with([ user, :assistant ], hash_including(locals: { message: reply, activity: "Searching your recipes…" }))
    expect(reply.content).to eq "Looking.\n\nNone."
  end

  it "answers a call to a tool the agent doesn't have with an error" do
    client = FakeClaude.new(tool_uses: [ { name: "delete_recipe", input: {} } ]).and_then([ "Sorry." ])

    run_agent(client)

    result = client.requests.last[:messages].last[:content].sole
    expect(result).to include(is_error: true, content: { error: "There's no tool called delete_recipe." }.to_json)
  end

  it "stops when the model hands the conversation to another agent" do
    client = FakeClaude.new(tool_uses: [ { name: "transfer_to_recommend", input: {} } ])

    responses = run_agent(client, agent: Assistant::Router.new(user))

    expect(responses.size).to eq 1
    expect(run.steps.pluck(:name)).to eq [ "router" ]
  end

  it "tells the agent to answer once it has used its tool calls, and raises if it carries on" do
    search = { name: "search_recipes", input: {} }
    client = FakeClaude.new(tool_uses: [ search ])
    9.times { client.and_then(tool_uses: [ search ]) }

    expect { run_agent(client) }.to raise_error("recommend kept calling tools past the limit")

    searches = run.steps.where(name: "search_recipes")
    expect(searches.count).to eq 9
    expect(searches.last.output).to eq("error" => "You've used all 8 tool calls for this reply. Answer with what you have.")
  end
end
