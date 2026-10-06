# A user's food preferences, as small facts the assistant reads when it recommends recipes.
class CreatePreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category, null: false
      t.string :value, null: false
      t.timestamps
    end

    # The same fact can't be listed twice in a category, whatever its letter case.
    add_index :preferences, "user_id, category, lower(value)", unique: true,
                                                                name: "index_preferences_on_user_category_and_value"
    # A household is a single fact, e.g. "4 people".
    add_index :preferences, :user_id, unique: true, where: "category = 'household'",
                                      name: "index_preferences_on_user_household"
    add_check_constraint :preferences, "category IN ('diet', 'likes', 'dislikes', 'avoid', 'household')",
                         name: "preferences_category_known"
  end
end
