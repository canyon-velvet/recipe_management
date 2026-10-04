# A recipe link can be saved once per user, so importing a page you already have is caught.
class AddUniqueRecipeLinkPerUser < ActiveRecord::Migration[8.1]
  def up
    # Blank links mean "no link"; only real links need to be unique.
    execute "UPDATE recipes SET source_url = NULL WHERE btrim(source_url) = ''"
    add_index :recipes, [ :user_id, :source_url ], unique: true, where: "source_url IS NOT NULL"
  end

  def down
    remove_index :recipes, [ :user_id, :source_url ]
  end
end
