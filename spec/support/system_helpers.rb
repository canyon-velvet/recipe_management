module SystemHelpers
  def log_in_as(user, password: "password")
    visit login_path
    fill_in "Username", with: user.username
    fill_in "Password", with: password
    click_button "Log in"
    expect(page).to have_text("Logged in.")
  end

  # A recipe of the user's, with ingredients given as name => aisle key. Ingredients the user already has are reused.
  def create_recipe(user, name, tags:, ingredients:, **attributes)
    recipe = build(:recipe, user: user, name: name, tags: tags, **attributes)
    ingredients.each do |ingredient_name, aisle_key|
      ingredient = user.ingredients.named(ingredient_name).first ||
                   create(:ingredient, user: user, name: ingredient_name, aisle_key: aisle_key)
      recipe.recipe_ingredients.build(ingredient: ingredient)
    end
    recipe.save!
  end
end

RSpec.configure do |config|
  config.include SystemHelpers, type: :system
end
