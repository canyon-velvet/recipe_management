# The drafts an assistant reply imported, shown as cards under it that follow the import as it's read.
class AddDraftIdsToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :draft_ids, :bigint, array: true, default: [], null: false
  end
end
