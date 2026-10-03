class CreateDrafts < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :status, null: false, default: "reading"
      t.string :source_url
      t.text :source_text
      t.string :failure_reason
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end

    add_index :drafts, [ :user_id, :created_at ]
    # The same link can't be imported twice; pasted text has no link.
    add_index :drafts, [ :user_id, :source_url ], unique: true, where: "source_url IS NOT NULL"
  end
end
