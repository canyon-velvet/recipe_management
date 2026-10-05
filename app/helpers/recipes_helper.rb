module RecipesHelper
  # The recipe's known servings and times for the recipe page, e.g. ["Serves 4", "Prep 15 min", "Total 1 hr 15 min"].
  def recipe_facts(recipe)
    facts = []
    facts << t("recipes.facts.servings", count: recipe.servings) if recipe.servings
    { prep: recipe.prep_minutes, cook: recipe.cook_minutes, total: recipe.total_minutes }.each do |key, minutes|
      facts << t("recipes.facts.#{key}", time: duration_label(minutes)) if minutes
    end
    facts
  end

  # 45 → "45 min", 75 → "1 hr 15 min", 120 → "2 hr"
  def duration_label(minutes)
    hours, rest = minutes.divmod(60)
    parts = []
    parts << t("recipes.facts.hours", count: hours) if hours.positive?
    parts << t("recipes.facts.minutes", count: rest) if rest.positive?
    parts.join(" ")
  end
end
