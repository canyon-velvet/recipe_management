class CreateMealSlotRecipes < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_slot_recipes do |t|
      t.references :meal_slot, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.boolean :add_to_grocery_list, null: false, default: true

      t.timestamps
    end
  end
end
