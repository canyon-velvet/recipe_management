# Saves a preference the assistant suggested, when the user clicks Save on its card (see
# Assistant::Tools::SuggestPreference). A household suggestion replaces the household the user has, as its card
# said. Saving it twice (a double click, or the fact added on the Preferences page meanwhile) just marks it saved.
#
# The reply is locked throughout, so a Save and a Skip on the same card at once can't both go through.
#
# Returns whether the suggestion is saved.
class SaveSuggestedPreferenceService
  def initialize(message, index)
    @message = message
    @index = index
  end

  def call
    @message.with_lock do
      suggestion = @message.preference_suggestions.fetch(@index)
      next suggestion["state"] == "saved" unless suggestion["state"] == "pending"
      next false unless save_preference(suggestion)

      @message.decide_suggestion!(@index, "saved")
    end
  end

  private

  def save_preference(suggestion)
    user = @message.conversation.user
    # The one household fact is changed in place, so a failed save never loses the old one.
    preference = (user.preferences.household.first if suggestion["category"] == "household") ||
                 user.preferences.build(category: suggestion["category"])
    preference.value = suggestion["value"]
    # Plain save rather than save_once: inside the lock's transaction, a caught unique-index error would leave the
    # transaction unusable. The validation still catches a fact the user already has.
    preference.save || preference.errors.of_kind?(:value, :taken)
  end
end
