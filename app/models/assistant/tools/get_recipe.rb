module Assistant
  module Tools
    # Reads one of the user's recipes in full.
    class GetRecipe < Tool
      NAME = "get_recipe"

      def description
        "Read one of the user's recipes in full: description, servings, times, tags, ingredients with amounts, " \
          "and steps, plus any items on the user's avoid list it contains, under \"avoided\"."
      end

      def input_schema = { type: "object", properties: { id: { type: "integer" } }, required: [ "id" ] }

      def activity = I18n.t("assistant.searching")

      private

      def execute(input)
        recipe = @user.recipes.includes(:tags, :steps, recipe_ingredients: :ingredient).find_by(id: input[:id])
        return { error: "There's no recipe with id #{input[:id]}." } unless recipe

        @turn.found([ recipe ])
        details = { id: recipe.id, name: recipe.name, description: recipe.description, tags: recipe.tags.map(&:key),
                    servings: recipe.servings, prep_minutes: recipe.prep_minutes, cook_minutes: recipe.cook_minutes,
                    total_minutes: recipe.total_minutes,
                    ingredients: recipe.recipe_ingredients.map { |row|
                      [ row.quantity, row.unit, row.ingredient.name ].compact_blank.join(" ")
                    },
                    steps: recipe.steps.map(&:body) }
        avoided = recipe.avoided_items(@user.avoided_ingredients)
        avoided.any? ? details.merge(avoided: avoided) : details
      end
    end
  end
end
