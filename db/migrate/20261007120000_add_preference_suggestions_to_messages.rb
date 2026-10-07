# The preferences an assistant reply suggested saving, shown as cards the user saves or dismisses:
# [{ "category" => "avoid", "value" => "peanut", "replaces" => nil, "state" => "pending" | "saved" | "dismissed" }].
class AddPreferenceSuggestionsToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :preference_suggestions, :jsonb, default: [], null: false
  end
end
