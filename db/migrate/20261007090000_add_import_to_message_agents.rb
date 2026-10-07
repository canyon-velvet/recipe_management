# The Import specialist writes replies too.
class AddImportToMessageAgents < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :messages, "agent IN ('router', 'recommend')", name: "messages_agent_known"
    add_check_constraint :messages, "agent IN ('router', 'recommend', 'import')", name: "messages_agent_known"
  end
end
