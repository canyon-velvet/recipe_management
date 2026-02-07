# Idempotent seed data — safe to run multiple times

# Ingredient Categories
%w[香料 油 酒 调料 面粉 熟食 蛋奶 谷物 菇类 水果 蔬菜 肉类].each do |name|
  IngredientCategory.find_or_create_by!(name: name)
end
puts "Seeded #{IngredientCategory.count} ingredient categories"

# Grocery Store Types
%w[中国超市 美国超市].each do |name|
  GroceryStoreType.find_or_create_by!(name: name)
end
puts "Seeded #{GroceryStoreType.count} grocery store types"

# Admin user (only in development)
if Rails.env.development?
  User.find_or_create_by!(username: "admin") do |user|
    user.password = "password"
    user.admin = true
  end
  puts "Seeded admin user (username: admin, password: password)"
end
