class CreateMealPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plans do |t|
      t.string :name
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :meal_plans, [ :user_id, :start_date ], unique: true
  end
end
