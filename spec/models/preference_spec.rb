require "rails_helper"

RSpec.describe Preference do
  let(:user) { create(:user) }

  it "tidies the value's spaces" do
    expect(create(:preference, user: user, value: "  spicy   food ").value).to eq "spicy food"
  end

  it "needs a value of at most 100 characters" do
    expect(build(:preference, user: user, value: " ")).not_to be_valid
    expect(build(:preference, user: user, value: "x" * 101)).not_to be_valid
  end

  it "only takes the known categories" do
    expect(build(:preference, user: user, category: "mood")).not_to be_valid
  end

  it "doesn't list the same fact twice in a category, whatever the case" do
    create(:preference, user: user, category: "avoid", value: "Peanuts")

    expect(build(:preference, user: user, category: "avoid", value: "peanuts")).not_to be_valid
    expect(build(:preference, user: user, category: "dislikes", value: "peanuts")).to be_valid
    expect(build(:preference, user: create(:user), category: "avoid", value: "peanuts")).to be_valid
  end

  it "keeps a single household fact per user" do
    create(:preference, user: user, category: "household", value: "4 people")
    second = build(:preference, user: user, category: "household", value: "2 adults")

    expect(second).not_to be_valid
    expect(second.errors[:base]).to eq [ "Household already has a value. Remove it to add another." ]
  end

  describe "database constraints" do
    it "allows one household fact per user" do
      create(:preference, user: user, category: "household", value: "4 people")

      expect { Preference.insert_all!([ { user_id: user.id, category: "household", value: "2 adults" } ]) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows only the known categories" do
      expect { Preference.insert_all!([ { user_id: user.id, category: "mood", value: "happy" } ]) }
        .to raise_error(ActiveRecord::StatementInvalid, /preferences_category_known/)
    end
  end
end
