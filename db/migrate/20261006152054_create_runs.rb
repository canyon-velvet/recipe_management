# One attempt by the assistant to write a reply: which model ran, how it went, and what it cost in tokens.
# The reply message is what the user sees; the run is the record of how it was produced.
class CreateRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :runs do |t|
      t.references :message, null: false, foreign_key: true, index: { unique: true }
      t.string :model, null: false
      t.string :status, null: false, default: "running"
      t.integer :input_tokens
      t.integer :output_tokens
      t.string :error
      t.datetime :finished_at
      t.timestamps
    end
    add_check_constraint :runs, "status IN ('running', 'succeeded', 'failed')", name: "runs_status_known"
  end
end
