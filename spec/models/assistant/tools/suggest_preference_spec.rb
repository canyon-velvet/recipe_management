require "rails_helper"

RSpec.describe Assistant::Tools::SuggestPreference do
  let(:user) { create(:user) }
  let(:turn) { Assistant::Turn.new }
  let(:tool) { described_class.new(user, turn) }

  it "suggests a fact for the user to save, without saving it" do
    expect(tool.call({ category: "avoid", value: "  peanut " })).to eq(result: "suggested")

    expect(turn.suggestions).to eq [ { "category" => "avoid", "value" => "peanut", "replaces" => nil,
                                       "state" => "pending" } ]
    expect(user.preferences).to be_empty
  end

  it "doesn't suggest a fact the user already has, or the same one twice" do
    create(:preference, user: user, category: "diet", value: "Vegetarian")

    expect(tool.call({ category: "diet", value: "vegetarian" })).to eq(result: "already_saved")
    tool.call({ category: "likes", value: "spicy food" })
    tool.call({ category: "likes", value: "Spicy food" })

    expect(turn.suggestions.pluck("value")).to eq [ "spicy food" ]
  end

  it "offers to replace the household the user has" do
    create(:preference, user: user, category: "household", value: "2 adults")

    expect(tool.call({ category: "household", value: "3 adults" })).to eq(result: "suggested", replaces: "2 adults")
    expect(turn.suggestions.sole).to include("replaces" => "2 adults")
  end

  it "refuses unknown categories, blank or long facts, and more than a few per reply" do
    expect(tool.call({ category: "mood", value: "happy" })).to eq(error: "Unknown category mood.")
    expect(tool.call({ category: "likes", value: " " })).to eq(error: "Give the fact in at most 100 characters.")
    expect(tool.call({ category: "likes", value: "x" * 101 })).to eq(error: "Give the fact in at most 100 characters.")

    %w[tofu rice noodles].each { |value| tool.call({ category: "likes", value: value }) }
    expect(tool.call({ category: "likes", value: "eggs" })).to eq(error: "You can suggest at most 3 facts per reply.")
  end

  it "tells Claude the categories it can use" do
    expect(tool.definition.dig(:input_schema, :properties, :category, :enum))
      .to eq %w[diet likes dislikes avoid household]
  end
end
