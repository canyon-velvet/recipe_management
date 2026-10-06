module Assistant
  module Tools
    # Searches the user's recipes by tags, ingredients, time, servings and name. A recipe with an ingredient on the
    # user's avoid list is still returned, with the avoided items flagged, so it can be recommended with a warning.
    class SearchRecipes < Tool
      NAME = "search_recipes"
      # Recipes one search returns at most: plenty to choose from without filling Claude's context.
      LIMIT = 20

      def description
        "Search the user's saved recipes. Every filter is optional, and a recipe must match all the ones given. " \
          "Returns at most #{LIMIT} recipes, most recently changed first, with their tags and ingredients. A " \
          "recipe with an ingredient on the user's avoid list lists those items under \"avoided\"."
      end

      def input_schema
        {
          type: "object",
          properties: {
            tags: { type: "array", items: { type: "string", enum: Tag.ordered.pluck(:key) },
                    description: "Tag keys the recipe must all have." },
            ingredients: { type: "array", items: { type: "string" },
                           description: "Words that must each be part of an ingredient's name, e.g. \"egg\"." },
            max_total_minutes: { type: "integer",
                                 description: "Longest total time. Recipes without a total time are left out." },
            min_servings: { type: "integer", description: "Fewest servings. Recipes without servings are left out." },
            name: { type: "string", description: "Text the recipe's name must contain." }
          }
        }
      end

      def activity = I18n.t("assistant.searching")

      private

      def execute(input)
        recipes = @user.recipes
        Array(input[:tags]).each { |key| recipes = recipes.tagged(key.to_s) }
        Array(input[:ingredients]).each { |text| recipes = recipes.with_ingredient(text.to_s) }
        recipes = recipes.where(total_minutes: ..input[:max_total_minutes]) if input[:max_total_minutes].is_a?(Integer)
        recipes = recipes.where(servings: input[:min_servings]..) if input[:min_servings].is_a?(Integer)
        recipes = recipes.search_by_name(input[:name].to_s)

        found = recipes.includes(:tags, recipe_ingredients: :ingredient).order(updated_at: :desc)
                       .limit(LIMIT + 1).to_a
        returned = found.first(LIMIT)
        @turn.found(returned)
        avoid_list = @user.avoided_ingredients
        { recipes: returned.map { |recipe| summary(recipe, avoid_list) }, more: found.size > LIMIT }
      end

      def summary(recipe, avoid_list)
        summary = { id: recipe.id, name: recipe.name, tags: recipe.tags.map(&:key),
                    total_minutes: recipe.total_minutes, servings: recipe.servings,
                    ingredients: recipe.recipe_ingredients.map { _1.ingredient.name } }
        avoided = recipe.avoided_items(avoid_list)
        avoided.any? ? summary.merge(avoided: avoided) : summary
      end
    end
  end
end
