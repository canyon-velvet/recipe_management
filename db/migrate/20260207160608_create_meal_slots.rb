class CreateMealSlots < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_slots do |t|
      t.references :meal_plan, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.integer :meal_type, null: false

      t.timestamps
    end
    add_index :meal_slots, [:meal_plan_id, :day_of_week, :meal_type], unique: true, name: "index_meal_slots_uniqueness"
  end
end
