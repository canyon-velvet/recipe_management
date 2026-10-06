# The Preferences page: a card per category, each in its own Turbo Frame, so adding or removing a fact only
# re-renders that card.
class PreferencesController < ApplicationController
  def index
    @preferences = current_user.preferences.ordered.group_by(&:category)
  end

  def create
    preference = current_user.preferences.build(preference_params)
    return head :unprocessable_entity unless Preference::CATEGORIES.include?(preference.category)

    if save(preference)
      render_card(preference.category)
    else
      render_card(preference.category, new_preference: preference, status: :unprocessable_entity)
    end
  end

  def destroy
    preference = current_user.preferences.find(params[:id])
    preference.destroy!
    render_card(preference.category)
  end

  private

  def preference_params
    params.require(:preference).permit(:category, :value)
  end

  # Two tabs adding the same fact at once can both pass validation; the unique index stops the second, and checking
  # again gives it the usual error.
  def save(preference)
    preference.save
  rescue ActiveRecord::RecordNotUnique
    preference.valid?
    false
  end

  # Keeps the keyboard in the card's box after the card is replaced.
  def render_card(category, new_preference: nil, status: :ok)
    render partial: "preferences/card", status: status, locals: {
      category: category, preferences: current_user.preferences.where(category: category).ordered,
      new_preference: new_preference, focus: true
    }
  end
end
