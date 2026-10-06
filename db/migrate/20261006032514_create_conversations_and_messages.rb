# The assistant's chats: a user's conversations, each a list of messages from the user and the assistant.
class CreateConversationsAndMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      # Indexed by the index below, which starts with user_id.
      t.references :user, null: false, foreign_key: true, index: false
      t.timestamps
    end
    # The panel shows the user's newest conversation.
    add_index :conversations, [ :user_id, :created_at ]

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true, index: false
      t.string :role, null: false
      t.text :content, null: false, default: ""
      # pending: the assistant's reply is still being written; failed: it couldn't be.
      t.string :status, null: false, default: "done"
      t.timestamps
    end
    add_index :messages, [ :conversation_id, :created_at ]
    add_check_constraint :messages, "role IN ('user', 'assistant')", name: "messages_role_known"
    add_check_constraint :messages, "status IN ('pending', 'done', 'failed')", name: "messages_status_known"
  end
end
