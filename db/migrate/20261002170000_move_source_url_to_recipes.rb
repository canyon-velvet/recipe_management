# A source (a website, cookbook, or person) is shared by many recipes, so the link to the original
# recipe page belongs on each recipe. Existing source links are copied onto their recipes.
class MoveSourceUrlToRecipes < ActiveRecord::Migration[8.1]
  def up
    add_column :recipes, :source_url, :string

    execute <<~SQL
      UPDATE recipes SET source_url = sources.url
      FROM sources
      WHERE recipes.source_id = sources.id AND sources.url <> ''
    SQL

    remove_column :sources, :url
  end

  def down
    add_column :sources, :url, :string

    execute <<~SQL
      UPDATE sources SET url = (
        SELECT recipes.source_url FROM recipes
        WHERE recipes.source_id = sources.id AND recipes.source_url <> ''
        ORDER BY recipes.id LIMIT 1
      )
    SQL

    remove_column :recipes, :source_url
  end
end
