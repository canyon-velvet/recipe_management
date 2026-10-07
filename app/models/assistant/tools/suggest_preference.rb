module Assistant
  module Tools
    # Offers to save a lasting fact the user told the assistant about what they eat or who they cook for. It only
    # suggests: the user saves it with a click on the suggestion's card (see SaveSuggestedPreferenceService), so the
    # model can never change their preferences itself.
    class SuggestPreference < Tool
      NAME = "suggest_preference"
      MAX_PER_REPLY = 3

      class Input < Anthropic::BaseModel
        required :category, Anthropic::EnumOf[*Preference::CATEGORIES.map(&:to_sym)],
                 doc: "diet: how they eat (e.g. vegetarian). likes and dislikes: flavors, cuisines or ingredients. " \
                      "avoid: what they must never eat, e.g. an allergy. household: who they cook for."
        required :value, String,
                 doc: "The fact in a few words, in the language they used, as it would be listed on their " \
                      "Preferences page, e.g. \"vegetarian\", \"peanut\", \"2 adults and a toddler\"."
      end

      def description
        "Offer to save a lasting fact the user just told you about what they eat or who they cook for, so you " \
          "remember it next time. They see it as a card with Save and No thanks buttons; you can't save it " \
          "yourself, so don't ask them to confirm in your reply. Only for facts they stated, not guesses, and " \
          "not for what's already in their preferences or what you suggested earlier in this chat (saved or " \
          "dismissed). At most #{MAX_PER_REPLY} per reply."
      end

      private

      def execute(input)
        category = input[:category].to_s
        value = input[:value].to_s.squish
        return { error: "Unknown category #{category}." } unless Preference::CATEGORIES.include?(category)
        return { error: "Give the fact in at most 100 characters." } if value.empty? || value.length > 100
        # Counted on the reply's Turn, which the router and the specialist it hands over to share.
        if @turn.suggestions.size >= MAX_PER_REPLY
          return { error: "You can suggest at most #{MAX_PER_REPLY} facts per reply." }
        end

        preferences = @user.preferences.where(category: category)
        return { result: "already_saved" } if preferences.any? { |preference| preference.value.casecmp?(value) }

        replaces = preferences.first&.value if category == "household"
        @turn.suggest(category: category, value: value, replaces: replaces)
        { result: "suggested", replaces: replaces }.compact
      end
    end
  end
end
