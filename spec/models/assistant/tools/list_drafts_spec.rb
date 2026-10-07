require "rails_helper"

RSpec.describe Assistant::Tools::ListDrafts do
  let(:user) { create(:user) }
  let(:tool) { described_class.new(user, Assistant::Turn.new) }

  it "lists the user's newest drafts and how each import is going" do
    user.drafts.create!(source_url: "https://example.com/a", status: :ready, data: { "name" => "Mapo tofu" },
                        created_at: 2.hours.ago)
    user.drafts.create!(source_url: "https://example.com/b", status: :failed, failure_reason: "not_a_recipe",
                        created_at: 1.hour.ago)
    create(:user).drafts.create!(source_url: "https://example.com/c")

    drafts = tool.call({})[:drafts]

    expect(drafts.pluck(:status)).to eq %w[failed ready]
    expect(drafts.first).to include(why_it_failed: "We didn't find a recipe here.")
    expect(drafts.last).to include(title: "Mapo tofu")
    expect(drafts.last).not_to have_key(:why_it_failed)
  end

  it "says what it's doing while it runs" do
    expect(tool.activity).to eq "Checking your Draft box…"
  end
end
