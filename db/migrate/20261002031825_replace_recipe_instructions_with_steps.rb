# Replaces each recipe's single instructions text with ordered steps.
# Numbered lines ("1. ...", "2、...", "Step 3: ...") start new steps; other lines continue the current one.
# Text without numbering is split on blank lines. Rolling back joins the steps into a numbered list again.
class ReplaceRecipeInstructionsWithSteps < ActiveRecord::Migration[8.1]
  class Recipe < ActiveRecord::Base
    self.table_name = "recipes"
  end

  class RecipeStep < ActiveRecord::Base
    self.table_name = "recipe_steps"
  end

  STEP_NUMBER = /\A\s*(?:step\s*)?\d+\s*[.、:：)）]\s*/i

  def up
    create_table :recipe_steps do |t|
      t.references :recipe, null: false, foreign_key: true
      t.integer :position, null: false
      t.text :body, null: false
      t.timestamps
    end
    add_index :recipe_steps, [ :recipe_id, :position ]

    Recipe.find_each do |recipe|
      split_into_steps(recipe.instructions).each.with_index(1) do |body, position|
        RecipeStep.create!(recipe_id: recipe.id, position: position, body: body)
      end
    end

    remove_column :recipes, :instructions
  end

  def down
    add_column :recipes, :instructions, :text
    Recipe.reset_column_information

    Recipe.find_each do |recipe|
      bodies = RecipeStep.where(recipe_id: recipe.id).order(:position).pluck(:body)
      recipe.update_columns(instructions: bodies.each.with_index(1).map { |body, i| "#{i}. #{body}" }.join("\n"))
    end

    change_column_null :recipes, :instructions, false, ""
    drop_table :recipe_steps
  end

  private

  def split_into_steps(text)
    lines = text.to_s.lines.map(&:strip)
    return paragraphs(text) if lines.none? { |line| line.match?(STEP_NUMBER) }

    lines.reject(&:blank?).each_with_object([]) do |line, steps|
      if line.match?(STEP_NUMBER) || steps.empty?
        steps << line.sub(STEP_NUMBER, "")
      else
        steps[-1] = "#{steps[-1]}\n#{line}"
      end
    end
  end

  def paragraphs(text)
    text.to_s.split(/\n\s*\n/).map(&:strip).reject(&:blank?)
  end
end
