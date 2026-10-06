module Assistant
  # The specialist that suggests recipes from the user's own collection, following their preferences.
  class RecommendSpecialist < Agent
    MODEL = "claude-sonnet-5-5"
    NAME = "recommend"
    TITLE = "Recommend"
    # For the router's transfer tool: when to hand over.
    HANDLES = "searches the user's saved recipes and suggests some. Use it when they want recipes from their own " \
              "collection: what to cook tonight, something with eggs, a quick dinner, a dish for guests"

    PROMPT = <<~PROMPT.freeze
      You are the Recommend specialist of the assistant in a home recipe app. You suggest recipes from the user's own
      saved collection, never from anywhere else. If nothing fits, say so and suggest widening the search (another
      tag, fewer filters) or importing a recipe from a link.

      Use search_recipes to find candidates and get_recipe to read one in full, for example to judge from its
      ingredients how spicy it is. Ingredient names are as the user wrote them, in Chinese or English; try both
      languages when one finds nothing. Then call show_recipes with the recipes you recommend, so they appear as
      cards under your reply. Only recommend recipes a tool returned while you wrote this reply.

      Follow the user's preferences. "Avoid" is strict: search_recipes already leaves out recipes whose ingredients
      contain an avoided item, and never recommend a recipe you know has one. The others are soft: lean towards
      their diet and likes, away from dislikes, and suit the household.

      Your reply is a sentence about each recipe you recommend, by name, and why it fits. The cards only link to
      the recipes; they don't replace your reply, so never just point to them. Keep it short, and don't describe
      your searches.
    PROMPT

    # The instructions, then what the user has (their preferences, the tags and their ingredients' names), then the
    # language rule.
    def system_prompt
      <<~PROMPT
        #{PROMPT}
        The user's preferences:
        #{preferences_list}

        Tags (key: name):
        #{Tag.ordered.map { |tag| "#{tag.key}: #{tag.name}" }.join("\n")}

        Ingredients in the user's recipes: #{@user.ingredients.order(:name).pluck(:name).join(", ")}

        #{language_rule}
      PROMPT
    end

    private

    def build_tools = [ Tools::SearchRecipes, Tools::GetRecipe, Tools::ShowRecipes ].map { |tool| tool.new(@user) }

    def request_options
      {
        output_config: { effort: :medium },
        # If the model declines, the API retries on a suitable fallback model within the same call.
        betas: [ "server-side-fallback-2026-07-01" ], fallbacks: :default
      }
    end

    def preferences_list
      preferences = @user.preferences.ordered
      return "(none yet)" if preferences.empty?

      preferences.map { |preference| "- #{preference.category}: #{preference.value}" }.join("\n")
    end
  end
end
