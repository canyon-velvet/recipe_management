# Why the assistant recommends each recipe card under a reply, shown on the card: { "<recipe id>" => "reason" }.
# Older replies have none, and their cards show without one.
class AddCardReasonsToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :card_reasons, :jsonb, default: {}, null: false
  end
end
