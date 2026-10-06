module Assistant
  module Tools
    # Picks recipes to show as cards under the reply, each with why it fits, shown on the card. The reason is required:
    # left to the reply's text, the explanation often went missing, as the model thinks it through out of sight and
    # then just points to the cards.
    #
    # Only recipes another tool returned during this reply can be shown (see Turn); the others are left out and the
    # model is told why. The last call wins.
    class ShowRecipes < Tool
      NAME = "show_recipes"

      # The recipes chosen so far, in order, with why each fits: { recipe id => reason }.
      attr_reader :cards

      def initialize(user, turn)
        super
        @cards = {}
      end

      def description
        "Show recipes as cards under your reply, in this order, so the user can open them. Use the ids " \
          "search_recipes or get_recipe returned while you wrote this reply. Each card shows its why. Calling it " \
          "again replaces the cards."
      end

      def input_schema
        {
          type: "object",
          properties: {
            recipes: {
              type: "array",
              items: {
                type: "object",
                properties: {
                  id: { type: "integer" },
                  why: { type: "string",
                         description: "One short sentence, in the language of the user's latest message, on why " \
                                      "this recipe fits what they asked. Mention any avoided item it contains." }
                },
                required: [ "id", "why" ]
              }
            }
          },
          required: [ "recipes" ]
        }
      end

      private

      def execute(input)
        picks = Array(input[:recipes]).select { |pick| pick.is_a?(Hash) && pick[:id].is_a?(Integer) }
        if picks.any? { |pick| pick[:why].to_s.strip.empty? }
          @cards = {} # the last call wins, even a failed one
          return { error: "Give each recipe a short why." }
        end

        ids = picks.map { |pick| pick[:id] }.uniq
        @cards = picks.select { |pick| @turn.found?(pick[:id]) }.to_h { |pick| [ pick[:id], pick[:why].to_s.strip ] }
        return { shown: @cards.keys } if @cards.size == ids.size

        { shown: @cards.keys, not_shown: ids - @cards.keys,
          why: "Only recipes search_recipes or get_recipe returned during this reply can be shown. Look these up " \
               "first if you still want to recommend them." }
      end
    end
  end
end
