module Assistant
  # One reply's worth of work: the user's message it answers, and what the agent's tools have found while writing it.
  #
  # - Only recipes a tool returned can be shown as cards, so a card is always a real recipe of the user's that the
  #   agent looked at, not one it remembered or made up.
  # - Only links in the user's message can be imported, so the agent never imports a link it made up or read
  #   somewhere else.
  class Turn
    # The drafts the reply's imports started or found in the Draft box, shown as cards under the reply.
    attr_reader :draft_ids

    # question: the text of the user's message the reply answers.
    def initialize(question = nil)
      @question = question.to_s
      @recipe_ids = Set.new
      @draft_ids = []
    end

    def imported(draft)
      @draft_ids |= [ draft.id ]
    end

    def found(recipes)
      @recipe_ids.merge(recipes.map(&:id))
    end

    def found?(recipe_id) = @recipe_ids.include?(recipe_id)

    # The link as the user wrote it in their message, in canonical form (see RecipeLink), or nil if they didn't.
    # Importing this rather than Claude's copy keeps stray punctuation out of the link.
    def link_for(url)
      link = canonical(url.to_s)
      link if link && links.include?(link)
    end

    # The links in the user's message, in canonical form. The RFC 2396 parser is the one with #extract. It only reads
    # ASCII, so a link with raw non-ASCII characters (rare for recipe sites) is cut short and won't match.
    def links = @links ||= URI::RFC2396_PARSER.extract(@question, %w[http https]).map { canonical(_1) }.compact

    private

    # Punctuation after a link in a sentence ("…/mapo-tofu, and") isn't part of it. A closing bracket is, when the
    # link opened it: ".../Mapo_tofu_(dish)" keeps its ")", but "(see https://…/mapo-tofu)." loses ")." .
    def canonical(url)
      url = url.strip
      loop do
        trimmed = url.sub(/[.,;:!?'"]+\z/, "")
        trimmed = trimmed.chomp(")") if trimmed.count(")") > trimmed.count("(")
        trimmed = trimmed.chomp("]") if trimmed.count("]") > trimmed.count("[")
        break if trimmed == url

        url = trimmed
      end
      RecipeLink.normalize(url)
    end
  end
end
