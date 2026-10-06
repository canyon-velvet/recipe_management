module Assistant
  # What an agent's tools have found while it writes one reply: the recipes they returned. Only these can be shown as
  # cards, so a card is always a real recipe of the user's that the agent looked at, not one it remembered or made up.
  class Turn
    def initialize
      @recipe_ids = Set.new
    end

    def found(recipes)
      @recipe_ids.merge(recipes.map(&:id))
    end

    def found?(recipe_id) = @recipe_ids.include?(recipe_id)
  end
end
