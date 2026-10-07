# Saves a preference the assistant suggested, when the user clicks Save on its card (see
# Assistant::Tools::SuggestPreference). A household suggestion replaces the household the user has, as its card
# said. Saving it twice (a double click, or the fact added on the Preferences page meanwhile) just marks it saved.
#
# Returns whether the suggestion is saved.
class SaveSuggestedPreferenceService
  def initialize(message, index)
    @message = message
    @index = index
    @suggestion = message.preference_suggestions.fetch(index)
  end

  def call
    return @suggestion["state"] == "saved" unless @suggestion["state"] == "pending"

    return false unless save_preference

    @message.decide_suggestion!(@index, "saved")
    true
  end

  private

  def save_preference
    user = @message.conversation.user
    # The one household fact is changed in place, so a failed save never loses the old one.
    preference = (user.preferences.household.first if @suggestion["category"] == "household") ||
                 user.preferences.build(category: @suggestion["category"])
    preference.value = @suggestion["value"]
    preference.save_once || preference.errors.of_kind?(:value, :taken)
  end
end
