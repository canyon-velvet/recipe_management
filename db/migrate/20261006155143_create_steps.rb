# One thing that happened while the assistant wrote a reply, such as a model call: which model, its token usage, how
# long it took (created_at to finished_at), and any error. A run is made of steps; with the router and specialists a
# reply takes several.
class CreateSteps < ActiveRecord::Migration[8.1]
  def change
    create_table :steps do |t|
      t.references :run, null: false, foreign_key: true
      t.string :name, null: false
      t.string :model
      t.integer :input_tokens
      t.integer :output_tokens
      t.string :error
      t.datetime :finished_at
      t.timestamps
    end
  end
end
