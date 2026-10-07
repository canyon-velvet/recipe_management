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

    # The link as the user wrote it in their message, in canonical form (see RecipeLink), or nil if they didn't.
    # Importing this rather than Claude's copy keeps stray punctuation out of the link.
    def link_for(url)
      link = canonical(url.to_s)
      link if links.include?(link)
    end

    def asked_for?(url) = link_for(url).present?

    private

    # The RFC 2396 parser is the one with #extract. It only reads ASCII, so a link with raw non-ASCII characters
    # (rare for recipe sites) is cut short and won't match.
    def links = @links ||= URI::RFC2396_PARSER.extract(@question, %w[http https]).map { canonical(_1) }

    # Punctuation after a link in a sentence ("…/mapo-tofu, and") isn't part of it.
    def canonical(url) = RecipeLink.normalize(url.sub(/[.,;:!?)\]'"]+\z/, ""))
  end
end
