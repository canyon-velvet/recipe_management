require "rails_helper"

RSpec.describe Message do
  it "only takes the known roles and statuses, in the model and the database" do
    expect(build(:message, role: "system")).not_to be_valid
    expect(build(:message, status: "lost")).not_to be_valid
  end

  it "lets an assistant reply start empty" do
    expect(build(:message, role: "assistant", content: "", status: "pending")).to be_valid
  end

  describe "database constraints" do
    let(:conversation) { create(:conversation) }

    it "rejects an unknown role" do
      expect { Message.insert_all!([ { conversation_id: conversation.id, role: "system", content: "x" } ]) }
        .to raise_error(ActiveRecord::StatementInvalid, /messages_role_known/)
    end

    it "rejects an unknown status" do
      expect { Message.insert_all!([ { conversation_id: conversation.id, role: "user", status: "lost" } ]) }
        .to raise_error(ActiveRecord::StatementInvalid, /messages_status_known/)
    end
  end
end
