module MealPlansHelper
  def day_label(index)
    t(MealPlan::DAYS_OF_WEEK[index], scope: "meal_plans.days")
  end

  def meal_type_label(index)
    t(MealPlan::MEAL_TYPES[index], scope: "meal_plans.meal_types")
  end

  def format_week_range(meal_plan)
    "#{meal_plan.start_date.strftime('%m/%d')} - #{meal_plan.end_date.strftime('%m/%d')}"
  end
end
