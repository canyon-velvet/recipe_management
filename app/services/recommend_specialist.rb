# The Recommend specialist: suggests recipes from the user's own collection, following their preferences. The router
# hands it the conversation, and WriteReplyService runs it; this class holds its instructions and tools, and runs the
# tools. They only ever see the user's own recipes.
class RecommendSpecialist
  MODEL = "claude-sonnet-5-5"
  # Recipes one search returns at most: plenty to choose from without filling Claude's context.
  SEARCH_LIMIT = 20

  PROMPT = <<~PROMPT.freeze
    You are the Recommend specialist of the assistant in a home recipe app. You suggest recipes from the user's own
    saved collection, never from anywhere else. If nothing fits, say so and suggest widening the search (another tag,
    fewer filters) or importing a recipe from a link.

    Use search_recipes to find candidates and get_recipe to read one in full, for example to judge from its
    ingredients how spicy it is. Ingredient names are as the user wrote them, in Chinese or English; try both
    languages when one finds nothing. Then call show_recipes with the recipes you recommend, so they appear as cards
    under your reply, and mention each by name. Only recommend recipes a tool returned while you wrote this reply.

    Follow the user's preferences. "Avoid" is strict: search_recipes already leaves out recipes whose ingredients
    contain an avoided item, and never recommend a recipe you know has one. The others are soft: lean towards their
    diet and likes, away from dislikes, and suit the household.

    Reply in the language of the user's latest message. Keep it short: a sentence about each recipe and why it fits.
    Don't describe your searches.
  PROMPT

  attr_reader :shown_recipe_ids

  def initialize(user)
    @user = user
    @shown_recipe_ids = []
  end

  # The instructions, plus what the user has: their preferences, the tags and their ingredients' names.
  def system_prompt
    <<~PROMPT
      #{PROMPT}
      The user's preferences:
      #{preferences_list}

      Tags (key: name):
      #{tags.map { |tag| "#{tag.key}: #{tag.name}" }.join("\n")}

      Ingredients in the user's recipes: #{@user.ingredients.order(:name).pluck(:name).join(", ")}
    PROMPT
  end

  def tools
    [
      {
        name: "search_recipes",
        description: "Search the user's saved recipes. Every filter is optional, and a recipe must match all the " \
                     "ones given. Recipes with an ingredient on the user's avoid list are never returned. Returns at " \
                     "most #{SEARCH_LIMIT} recipes, most recently changed first, with their tags and ingredients.",
        input_schema: {
          type: "object",
          properties: {
            tags: { type: "array", items: { type: "string", enum: tags.map(&:key) },
                    description: "Tag keys the recipe must all have." },
            ingredients: { type: "array", items: { type: "string" },
                           description: "Words that must each be part of an ingredient's name, e.g. \"egg\"." },
            max_total_minutes: { type: "integer",
                                 description: "Longest total time. Recipes without a total time are left out." },
            min_servings: { type: "integer",
                            description: "Fewest servings. Recipes without servings are left out." },
            name: { type: "string", description: "Text the recipe's name must contain." }
          }
        }
      },
      {
        name: "get_recipe",
        description: "Read one of the user's recipes in full: description, servings, times, tags, ingredients " \
                     "with amounts, and steps.",
        input_schema: { type: "object", properties: { id: { type: "integer" } }, required: [ "id" ] }
      },
      {
        name: "show_recipes",
        description: "Show recipes as cards under your reply, in this order, so the user can open them. Use the " \
                     "ids search_recipes or get_recipe returned. Calling it again replaces the cards.",
        input_schema: {
          type: "object", properties: { ids: { type: "array", items: { type: "integer" } } }, required: [ "ids" ]
        }
      }
    ]
  end

  # Runs a tool with Claude's input and returns its result, which has an :error when the call didn't work.
  def run_tool(name, input)
    return { error: "The input isn't a JSON object." } unless input.is_a?(Hash)

    case name
    when "search_recipes" then search_recipes(input)
    when "get_recipe" then get_recipe(input)
    when "show_recipes" then show_recipes(input)
    else { error: "There's no tool called #{name}." }
    end
  end

  private

  def tags = @tags ||= Tag.ordered.to_a

  def preferences_list
    preferences = @user.preferences.ordered
    return "(none yet)" if preferences.empty?

    preferences.map { |preference| "- #{preference.category}: #{preference.value}" }.join("\n")
  end

  def search_recipes(input)
    recipes = @user.recipes.without_ingredients(@user.preferences.avoid.pluck(:value))
    Array(input[:tags]).each { |key| recipes = recipes.tagged(key.to_s) }
    Array(input[:ingredients]).each { |text| recipes = recipes.with_ingredient(text.to_s) }
    recipes = recipes.where(total_minutes: ..input[:max_total_minutes]) if input[:max_total_minutes].is_a?(Integer)
    recipes = recipes.where(servings: input[:min_servings]..) if input[:min_servings].is_a?(Integer)
    recipes = recipes.search_by_name(input[:name].to_s)

    found = recipes.includes(:tags, :ingredients).order(updated_at: :desc).limit(SEARCH_LIMIT + 1).to_a
    { recipes: found.first(SEARCH_LIMIT).map { |recipe| summary(recipe) }, more: found.size > SEARCH_LIMIT }
  end

  def get_recipe(input)
    recipe = @user.recipes.includes(:tags, :steps, recipe_ingredients: :ingredient).find_by(id: input[:id])
    return { error: "There's no recipe with id #{input[:id]}." } unless recipe

    { id: recipe.id, name: recipe.name, description: recipe.description, tags: recipe.tags.map(&:key),
      servings: recipe.servings, prep_minutes: recipe.prep_minutes, cook_minutes: recipe.cook_minutes,
      total_minutes: recipe.total_minutes,
      ingredients: recipe.recipe_ingredients.map { |row|
        [ row.quantity, row.unit, row.ingredient.name ].compact_blank.join(" ")
      },
      steps: recipe.steps.map(&:body) }
  end

  def show_recipes(input)
    ids = Array(input[:ids]).grep(Integer)
    found = @user.recipes.where(id: ids).ids
    @shown_recipe_ids = ids.select { |id| found.include?(id) }.uniq
    { shown: @shown_recipe_ids, not_found: ids - found }
  end

  def summary(recipe)
    { id: recipe.id, name: recipe.name, tags: recipe.tags.map(&:key), total_minutes: recipe.total_minutes,
      servings: recipe.servings, ingredients: recipe.ingredients.map(&:name) }
  end
end
