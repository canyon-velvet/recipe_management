# Idempotent seed data — safe to run multiple times

# Ingredient categories, in grocery-aisle order. Display names live in config/locales under `ingredient_categories`.
%w[produce meat_seafood dairy_eggs bakery pantry spices_seasonings frozen beverages other].each.with_index(1) do |key, i|
  IngredientCategory.find_or_initialize_by(key: key).update!(position: i * 10)
end
puts "Seeded #{IngredientCategory.count} ingredient categories"

# Admin user (only in development)
if Rails.env.development?
  User.find_or_create_by!(username: "admin") do |user|
    user.password = "password"
    user.admin = true
  end
  puts "Seeded admin user (username: admin, password: password)"
end
