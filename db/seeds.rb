# Idempotent seed data — safe to run multiple times

# Recipe tags, grouped by kind. Display names live in config/locales under `tags` and `tag_kinds`.
{
  "meal" => %w[breakfast lunch dinner snack dessert appetizer soup salad drink],
  "cuisine" => %w[chinese italian japanese mexican american],
  "diet" => %w[vegetarian vegan gluten_free],
  "convenience" => %w[quick kid_friendly make_ahead]
}.flat_map { |kind, keys| keys.map { [ kind, _1 ] } }.each.with_index(1) do |(kind, key), i|
  Tag.find_or_initialize_by(key: key).update!(kind: kind, position: i * 10)
end
puts "Seeded #{Tag.count} tags"

# Admin user (only in development)
if Rails.env.development?
  User.find_or_create_by!(username: "admin") do |user|
    user.password = "password"
    user.admin = true
  end
  puts "Seeded admin user (username: admin, password: password)"
end

# Aisles are per user; new users get the defaults on sign-up. Display names live in config/locales under `aisles`.
User.find_each { |user| Aisle.create_defaults_for(user) }
puts "Ensured default aisles for #{User.count} users"
