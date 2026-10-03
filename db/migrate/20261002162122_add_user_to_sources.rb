# Sources become per user (see docs/adr/0001). A source used by several users' recipes is copied
# so each user owns one; an unused source was visible to everyone, so every user gets a copy.
class AddUserToSources < ActiveRecord::Migration[8.1]
  class Source < ActiveRecord::Base
    self.table_name = "sources"
  end

  class Recipe < ActiveRecord::Base
    self.table_name = "recipes"
  end

  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  def up
    add_reference :sources, :user, foreign_key: true
    remove_index :sources, name: "index_sources_on_lowercase_name"
    Source.reset_column_information

    Source.where(user_id: nil).find_each do |source|
      owner_ids = Recipe.where(source_id: source.id).distinct.pluck(:user_id)
      owner_ids = User.pluck(:id) if owner_ids.empty?
      next source.destroy! if owner_ids.empty?

      first_owner, *other_owners = owner_ids
      source.update_columns(user_id: first_owner)
      other_owners.each do |user_id|
        copy = Source.create!(source.attributes.except("id", "created_at", "updated_at").merge("user_id" => user_id))
        Recipe.where(source_id: source.id, user_id: user_id).update_all(source_id: copy.id)
      end
    end

    change_column_null :sources, :user_id, false
    add_index :sources, "user_id, lower((name)::text)", unique: true, name: "index_sources_on_user_id_and_lowercase_name"
  end

  # Rolling back would have to merge each user's same-named sources, losing which recipe used whose.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
