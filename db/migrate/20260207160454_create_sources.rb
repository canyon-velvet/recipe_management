class CreateSources < ActiveRecord::Migration[8.1]
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :url

      t.timestamps
    end
    add_index :sources, "LOWER(name)", unique: true, name: "index_sources_on_lowercase_name"
  end
end
