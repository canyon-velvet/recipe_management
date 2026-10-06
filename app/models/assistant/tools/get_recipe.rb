module Assistant
  module Tools
    # Reads one of the user's recipes in full.
    class GetRecipe < Tool
      NAME = "get_recipe"

      def description
        "Read one of the user's recipes in full: description, servings, times, tags, ingredients with amounts, " \
          "and steps."
      end

      def input_schema = { type: "object", properties: { id: { type: "integer" } }, required: [ "id" ] }

      def activity = I18n.t("assistant.searching")

      private

      def execute(input)
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
    end
  end
end
