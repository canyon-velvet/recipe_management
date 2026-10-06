# Adds the Spicy tag, in a new Flavor group between Diet and Convenience, to databases that already have tags.
# New databases get it from db/seeds.rb.
class AddSpicyTag < ActiveRecord::Migration[8.1]
  class Tag < ActiveRecord::Base
    self.table_name = "tags"
  end

  class RecipeTag < ActiveRecord::Base
    self.table_name = "recipe_tags"
  end

  def up
    return if Tag.none? || Tag.exists?(key: "spicy")

    # Just before Convenience keeps the groups in order without renumbering the other tags.
    first_convenience = Tag.where(kind: "convenience").minimum(:position)
    position = first_convenience ? first_convenience - 5 : Tag.maximum(:position) + 10
    Tag.create!(key: "spicy", kind: "flavor", position: position)
  end

  def down
    spicy = Tag.find_by(key: "spicy")
    return unless spicy

    RecipeTag.where(tag_id: spicy.id).delete_all
    spicy.destroy!
  end
end
