module Assistant
  module Tools
    # Picks the user's recipes to show as cards under the reply. The last call wins.
    class ShowRecipes < Tool
      NAME = "show_recipes"

      # The recipes chosen so far, in order.
      attr_reader :recipe_ids

      def initialize(user)
        super
        @recipe_ids = []
      end

      def description
        "Show recipes as cards under your reply, in this order, so the user can open them. Use the ids " \
          "search_recipes or get_recipe returned. Calling it again replaces the cards."
      end

      def input_schema
        { type: "object", properties: { ids: { type: "array", items: { type: "integer" } } }, required: [ "ids" ] }
      end

      private

      def execute(input)
        ids = Array(input[:ids]).grep(Integer)
        found = @user.recipes.where(id: ids).ids
        @recipe_ids = ids.select { |id| found.include?(id) }.uniq
        # Said here, the last thing the model reads: told only in the instructions, it tends to just point to the
        # cards.
        { shown: @recipe_ids, not_found: ids - found,
          next: "The cards only link to the recipes. Now write your reply: a sentence about each recipe, by name, " \
                "and why it fits the user." }
      end
    end
  end
end
