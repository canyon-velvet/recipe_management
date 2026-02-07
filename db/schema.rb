# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_07_160624) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "grocery_list_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "grocery_list_id", null: false
    t.boolean "in_pantry", default: false, null: false
    t.bigint "ingredient_id", null: false
    t.integer "occurrence_count", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["grocery_list_id", "ingredient_id"], name: "index_grocery_list_items_uniqueness", unique: true
    t.index ["grocery_list_id"], name: "index_grocery_list_items_on_grocery_list_id"
    t.index ["ingredient_id"], name: "index_grocery_list_items_on_ingredient_id"
  end

  create_table "grocery_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "meal_plan_id", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_plan_id"], name: "index_grocery_lists_on_meal_plan_id", unique: true
  end

  create_table "grocery_store_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_grocery_store_types_on_name", unique: true
  end

  create_table "ingredient_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ingredient_categories_on_name", unique: true
  end

  create_table "ingredient_store_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "grocery_store_type_id", null: false
    t.bigint "ingredient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["grocery_store_type_id"], name: "index_ingredient_store_types_on_grocery_store_type_id"
    t.index ["ingredient_id", "grocery_store_type_id"], name: "index_ingredient_store_types_uniqueness", unique: true
    t.index ["ingredient_id"], name: "index_ingredient_store_types_on_ingredient_id"
  end

  create_table "ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_category_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((name)::text)", name: "index_ingredients_on_lowercase_name", unique: true
    t.index ["ingredient_category_id"], name: "index_ingredients_on_ingredient_category_id"
  end

  create_table "meal_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.string "name"
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "start_date"], name: "index_meal_plans_on_user_id_and_start_date", unique: true
    t.index ["user_id"], name: "index_meal_plans_on_user_id"
  end

  create_table "meal_slot_recipes", force: :cascade do |t|
    t.boolean "add_to_grocery_list", default: true, null: false
    t.datetime "created_at", null: false
    t.bigint "meal_slot_id", null: false
    t.bigint "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_slot_id"], name: "index_meal_slot_recipes_on_meal_slot_id"
    t.index ["recipe_id"], name: "index_meal_slot_recipes_on_recipe_id"
  end

  create_table "meal_slots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.bigint "meal_plan_id", null: false
    t.integer "meal_type", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_plan_id", "day_of_week", "meal_type"], name: "index_meal_slots_uniqueness", unique: true
    t.index ["meal_plan_id"], name: "index_meal_slots_on_meal_plan_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.string "quantity"
    t.bigint "recipe_id", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipe_ingredients_on_ingredient_id"
    t.index ["recipe_id", "ingredient_id"], name: "index_recipe_ingredients_on_recipe_id_and_ingredient_id", unique: true
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "instructions", null: false
    t.string "name", null: false
    t.bigint "source_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category"], name: "index_recipes_on_category"
    t.index ["source_id"], name: "index_recipes_on_source_id"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index "lower((name)::text)", name: "index_sources_on_lowercase_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index "lower((username)::text)", name: "index_users_on_lowercase_username", unique: true
  end

  add_foreign_key "grocery_list_items", "grocery_lists"
  add_foreign_key "grocery_list_items", "ingredients"
  add_foreign_key "grocery_lists", "meal_plans"
  add_foreign_key "ingredient_store_types", "grocery_store_types"
  add_foreign_key "ingredient_store_types", "ingredients"
  add_foreign_key "ingredients", "ingredient_categories"
  add_foreign_key "meal_plans", "users"
  add_foreign_key "meal_slot_recipes", "meal_slots"
  add_foreign_key "meal_slot_recipes", "recipes"
  add_foreign_key "meal_slots", "meal_plans"
  add_foreign_key "recipe_ingredients", "ingredients"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipes", "sources"
  add_foreign_key "recipes", "users"
end
