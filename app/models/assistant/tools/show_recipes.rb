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
        { shown: @recipe_ids, not_found: ids - found }
      end
    end
  end
end
