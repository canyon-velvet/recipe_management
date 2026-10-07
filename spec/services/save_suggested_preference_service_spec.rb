require "rails_helper"

RSpec.describe SaveSuggestedPreferenceService do
  let(:conversation) { create(:conversation) }
  let(:user) { conversation.user }

  def reply_suggesting(*suggestions)
    create(:message, conversation: conversation, role: "assistant", content: "Noted.",
                     preference_suggestions: suggestions.map { |category, value, replaces|
                       { "category" => category, "value" => value, "replaces" => replaces, "state" => "pending" }
                     })
  end

  it "saves the suggested preference and marks the suggestion saved" do
    reply = reply_suggesting([ "avoid", "peanut" ], [ "diet", "vegetarian" ])

    expect(described_class.new(reply, 1).call).to be true

    expect(user.preferences.pluck(:category, :value)).to eq [ [ "diet", "vegetarian" ] ]
    expect(reply.reload.preference_suggestions.pluck("state")).to eq %w[pending saved]
  end

  it "replaces the user's household, as the suggestion said" do
    household = create(:preference, user: user, category: "household", value: "2 adults")
    reply = reply_suggesting([ "household", "3 adults", "2 adults" ])

    expect(described_class.new(reply, 0).call).to be true

    expect(user.preferences.household.sole).to have_attributes(id: household.id, value: "3 adults")
  end

  it "treats a fact the user added meanwhile, or a second click, as saved" do
    reply = reply_suggesting([ "likes", "tofu" ])
    create(:preference, user: user, category: "likes", value: "Tofu")

    expect(described_class.new(reply, 0).call).to be true
    expect(described_class.new(reply.reload, 0).call).to be true
    expect(user.preferences.count).to eq 1
  end

  it "doesn't save a suggestion the user dismissed, and a later Skip doesn't undo a Save" do
    reply = reply_suggesting([ "likes", "tofu" ], [ "likes", "rice" ])
    reply.decide_suggestion!(0, "dismissed")

    expect(described_class.new(reply, 0).call).to be false
    expect(user.preferences).to be_empty

    described_class.new(reply, 1).call
    expect(reply.decide_suggestion!(1, "dismissed")).to be false
    expect(reply.reload.preference_suggestions.pluck("state")).to eq %w[dismissed saved]
  end
end
