class CreateRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :recipes do |t|
      t.string :name, null: false
      t.text :description
      t.string :category, null: false
      t.text :instructions, null: false
      t.references :source, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :recipes, :category
  end
end
