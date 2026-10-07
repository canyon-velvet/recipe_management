module Assistant
  # One reply's worth of work: the user's message it answers, and what the agent's tools have found while writing it.
  #
  # - Only recipes a tool returned can be shown as cards, so a card is always a real recipe of the user's that the
  #   agent looked at, not one it remembered or made up.
  # - Only links in the user's message can be imported, so the agent never imports a link it made up or read
  #   somewhere else.
  class Turn
    # question: the text of the user's message the reply answers.
    def initialize(question = nil)
      @question = question.to_s
      @recipe_ids = Set.new
    end

    def found(recipes)
      @recipe_ids.merge(recipes.map(&:id))
    end

    def found?(recipe_id) = @recipe_ids.include?(recipe_id)

    # Whether the user wrote this link in their message, compared in canonical form (see RecipeLink).
    def asked_for?(url) = url.present? && links.include?(canonical(url))

    private

    def links = @links ||= URI::DEFAULT_PARSER.extract(@question, %w[http https]).map { canonical(_1) }

    # Punctuation after a link in a sentence ("…/mapo-tofu, and") isn't part of it.
    def canonical(url) = RecipeLink.normalize(url.sub(/[.,;:!?)\]'"]+\z/, ""))
  end
end
