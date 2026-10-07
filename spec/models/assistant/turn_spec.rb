require "rails_helper"

RSpec.describe Assistant::Turn do
  describe "#asked_for?" do
    let(:turn) do
      described_class.new("Import https://Example.com/mapo-tofu?utm_source=feed, and 看看 " \
                          "https://m.xiachufang.com/recipe/1/。")
    end

    it "is true for links in the user's message, however they're written" do
      expect(turn.asked_for?("https://example.com/mapo-tofu")).to be true
      expect(turn.asked_for?("https://example.com/mapo-tofu?utm_source=feed,")).to be true
      expect(turn.asked_for?("https://www.xiachufang.com/recipe/1/")).to be true
    end

    it "is false for other links, or none" do
      expect(turn.asked_for?("https://example.com/other")).to be false
      expect(turn.asked_for?("")).to be false
      expect(described_class.new.asked_for?("https://example.com/mapo-tofu")).to be false
    end
  end
end
