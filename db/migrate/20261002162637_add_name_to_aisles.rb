# Aisles a user adds have a typed name instead of a translation key.
class AddNameToAisles < ActiveRecord::Migration[8.1]
  def change
    add_column :aisles, :name, :string
    change_column_null :aisles, :key, true
    add_index :aisles, "user_id, lower((name)::text)", unique: true, name: "index_aisles_on_user_id_and_lowercase_name"
  end
end
