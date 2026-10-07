require "rails_helper"

RSpec.describe Conversation do
  let(:user) { create(:user) }

  describe "#ask" do
    let(:conversation) { create(:conversation, user: user) }

    it "adds the user's message and a pending reply" do
      question, reply = conversation.ask("Dinner for 4?")

      expect(question).to have_attributes(role: "user", content: "Dinner for 4?", status: "done")
      expect(reply).to have_attributes(role: "assistant", content: "", status: "pending")
      expect(conversation.messages.reload).to eq [ question, reply ]
    end

    it "saves nothing for a blank or too long message" do
      [ " ", "x" * (Message::MAX_LENGTH + 1) ].each do |content|
        question, reply = conversation.ask(content)

        expect(question).not_to be_valid
        expect(reply).to be_nil
      end
      expect(conversation.messages.count).to eq 0
    end
  end

  describe "the daily limit" do
    it "counts only what the user sent today, across conversations" do
      first = user.current_conversation!
      second = user.conversations.create!
      travel_to(1.day.ago) { 5.times { first.messages.create!(role: :user, content: "Yesterday") } }
      (Message::DAILY_LIMIT - 1).times { |i| [ first, second ][i % 2].messages.create!(role: :user, content: "Hi") }
      first.messages.create!(role: :assistant, content: "Replies don't count")

      expect(user.assistant_limit_reached?).to be false

      second.messages.create!(role: :user, content: "The last one")
      expect(user.assistant_limit_reached?).to be true
    end
  end

  describe "the user's current conversation" do
    it "is the newest one, started with the first message" do
      expect(user.current_conversation).to be_nil

      first = user.current_conversation!
      expect(user.current_conversation!).to eq first
    end

    it "starts afresh on New chat, unless the current one is still empty" do
      current = user.current_conversation!
      expect(user.start_conversation).to eq current

      current.ask("Hello")
      fresh = user.start_conversation
      expect(fresh).not_to eq current
      expect(user.current_conversation).to eq fresh
    end
  end

  describe "what the assistant reads" do
    let(:conversation) { create(:conversation, user: user) }

    it "is the finished messages from the user's first on, with each reply's recipe cards noted" do
      tofu = create(:recipe, user: user, name: "Mapo tofu")
      conversation.messages.create!(role: :assistant, content: "Welcome!")
      conversation.ask("Tofu?").last.update!(content: "Try this.", status: :done, agent: :recommend,
                                             recipe_ids: [ tofu.id ])
      conversation.ask("Hot?").last.update!(status: :failed)
      conversation.ask("Hello?")

      expect(conversation.context(20)).to eq [
        { role: "user", content: "Tofu?" },
        { role: "assistant", content: "Try this.\n\n(Recipe cards shown: Mapo tofu (id #{tofu.id}))" },
        { role: "user", content: "Hot?" },
        { role: "user", content: "Hello?" }
      ]
      expect(conversation.last_agent).to eq "recommend"
    end

    it "notes the preferences a reply suggested and what the user decided" do
      conversation.ask("We're vegetarian, and no peanuts").last.update!(
        content: "", status: :done, preference_suggestions: [
          { "category" => "diet", "value" => "vegetarian", "state" => "dismissed" },
          { "category" => "avoid", "value" => "peanut", "state" => "saved" }
        ]
      )

      expect(conversation.context(20).last).to eq(
        role: "assistant",
        content: "(Suggested saving to preferences: diet: vegetarian (dismissed); avoid: peanut (saved))"
      )
    end

    it "notes each card's reason, and keeps a reply that's only cards" do
      tofu, rice = create_list(:recipe, 2, user: user)
      reply = conversation.ask("Dinner?").last
      reply.update!(content: "", status: :done, cards: { tofu.id => "Spicy.", rice.id => nil })

      cards = "#{tofu.name} (id #{tofu.id}): Spicy.; #{rice.name} (id #{rice.id})"
      expect(conversation.context(20).last).to eq(role: "assistant", content: "(Recipe cards shown: #{cards})")
    end
  end
end
