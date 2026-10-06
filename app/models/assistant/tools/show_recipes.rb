module Assistant
  module Tools
    # Picks recipes to show as cards under the reply. Only recipes another tool returned during this reply can be
    # shown (see Turn); the others are left out and the model is told why. The last call wins.
    class ShowRecipes < Tool
      NAME = "show_recipes"

      # The recipes chosen so far, in order.
      attr_reader :recipe_ids

      def initialize(user, turn)
        super
        @recipe_ids = []
      end

      def description
        "Show recipes as cards under your reply, in this order, so the user can open them. Use the ids " \
          "search_recipes or get_recipe returned while you wrote this reply. Calling it again replaces the cards."
      end

      def input_schema
        { type: "object", properties: { ids: { type: "array", items: { type: "integer" } } }, required: [ "ids" ] }
      end

      private

      def execute(input)
        ids = Array(input[:ids]).grep(Integer).uniq
        @recipe_ids = ids.select { |id| @turn.found?(id) }
        # Said here, the last thing the model reads: told only in the instructions, it tends to just point to the
        # cards.
        result = { shown: @recipe_ids,
                   next: "The cards only link to the recipes. Now write your reply: a sentence about each recipe, " \
                         "by name, and why it fits the user." }
        return result if @recipe_ids == ids

        result.merge(not_shown: ids - @recipe_ids,
                     why: "Only recipes search_recipes or get_recipe returned during this reply can be shown. Look " \
                          "these up first if you still want to recommend them.")
      end
    end
  end
end
