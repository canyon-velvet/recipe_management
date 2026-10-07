require "rails_helper"

RSpec.describe Assistant::ImportSpecialist do
  let(:user) { create(:user) }

  it "runs on Haiku with the import tools, and can show an already saved recipe as a card" do
    specialist = described_class.new(user)

    expect(specialist.request).to include(model: "claude-haiku-4-5", max_tokens: 8_000)
    expect(specialist.request).not_to have_key(:output_config) # Haiku 4.5 doesn't take an effort setting
    expect(specialist.request[:tools].pluck(:name)).to eq %w[import_recipe list_drafts show_recipes]
    expect(specialist.system_prompt).to include("Paste text instead", "at most\n3")
    expect(specialist.system_prompt.strip).to end_with("use English, the app's language.")
  end

  it "has to import a link the user sent before it answers, so it never claims an import it didn't start" do
    with_link = described_class.new(user, question: "Can you import https://example.com/mapo-tofu?")

    expect(with_link.first_call_options).to eq(tool_choice: { type: :tool, name: "import_recipe" })
  end

  it "has to call some tool before answering a message without a link, such as \"is my import done?\"" do
    expect(described_class.new(user, question: "Is my import done?").first_call_options)
      .to eq(tool_choice: { type: :any })
    expect(Assistant::RecommendSpecialist.new(user).first_call_options).to eq({})
  end

  it "only imports links from the message it answers" do
    specialist = described_class.new(user, question: "Import https://example.com/mapo-tofu")

    expect(specialist.turn.link_for("https://example.com/mapo-tofu")).to eq "https://example.com/mapo-tofu"
    expect(specialist.turn.link_for("https://example.com/other")).to be_nil
  end
end
