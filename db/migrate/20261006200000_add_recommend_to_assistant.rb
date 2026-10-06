# The Recommend specialist: which agent wrote each reply (the router reads it to keep follow-ups with the same
# specialist), the recipes shown as cards under it, and what each tool call was given and returned.
class AddRecommendToAssistant < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :agent, :string
    add_column :messages, :recipe_ids, :bigint, array: true, default: [], null: false
    add_check_constraint :messages, "agent IN ('router', 'recommend')", name: "messages_agent_known"

    add_column :steps, :input, :jsonb
    add_column :steps, :output, :jsonb
  end
end
