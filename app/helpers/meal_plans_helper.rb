module MealPlansHelper
  DAY_LABELS = %w[周一 周二 周三 周四 周五 周六 周日].freeze
  MEAL_TYPE_LABELS = %w[早餐 午餐 晚餐 加餐].freeze

  def day_label(index)
    DAY_LABELS[index]
  end

  def meal_type_label(index)
    MEAL_TYPE_LABELS[index]
  end

  def format_week_range(meal_plan)
    "#{meal_plan.start_date.strftime('%m/%d')} - #{meal_plan.end_date.strftime('%m/%d')}"
  end
end
