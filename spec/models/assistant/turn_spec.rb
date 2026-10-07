require "rails_helper"

RSpec.describe Assistant::Turn do
  it "lists the links in the user's message" do
    expect(described_class.new("Import https://example.com/a, and https://example.com/b.").links)
      .to eq %w[https://example.com/a https://example.com/b]
    expect(described_class.new("Is my import done?").links).to eq []
  end

  describe "#link_for" do
    let(:turn) do
      described_class.new("Import https://Example.com/mapo-tofu?utm_source=feed, and 看看 " \
                          "https://m.xiachufang.com/recipe/1/。 Also (see https://example.com/stew). And " \
                          "https://en.wikipedia.org/wiki/Mapo_tofu_(dish)!")
    end

    it "is the link as the user wrote it, in canonical form, however Claude copied it" do
      expect(turn.link_for("https://example.com/mapo-tofu")).to eq "https://example.com/mapo-tofu"
      expect(turn.link_for(" https://example.com/mapo-tofu?utm_source=feed, ")).to eq "https://example.com/mapo-tofu"
      expect(turn.link_for("https://www.xiachufang.com/recipe/1/")).to eq "https://www.xiachufang.com/recipe/1/"
    end

    it "keeps a closing bracket that belongs to the link, and drops one that closes the sentence" do
      expect(turn.link_for("https://example.com/stew).")).to eq "https://example.com/stew"
      expect(turn.link_for("https://en.wikipedia.org/wiki/Mapo_tofu_(dish)"))
        .to eq "https://en.wikipedia.org/wiki/Mapo_tofu_(dish)"
    end

    it "is nil for other links, or none" do
      expect(turn.link_for("https://example.com/other")).to be_nil
      expect(turn.link_for("")).to be_nil
      expect(turn.link_for(nil)).to be_nil
      expect(described_class.new.link_for("https://example.com/mapo-tofu")).to be_nil
    end
  end
end
