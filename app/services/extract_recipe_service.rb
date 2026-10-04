# Reads what a page says about its recipe. Most recipe sites embed a schema.org Recipe as JSON-LD; this maps it
# to plain fields. The page's visible text is kept too, for Claude when the structured data is missing or
# incomplete (下厨房 lists ingredients and steps only in the HTML).
class ExtractRecipeService
  MAX_TEXT_CHARS = 20_000
  NOISE = "script, style, noscript, template, svg, nav, header, footer, aside, form, iframe"

  # recipe: { name:, description:, ingredients: [lines], steps: [texts], hints: [category/cuisine/keywords] } or nil
  # title: the recipe or page title, known as soon as the page is fetched (shown while Claude reads the rest)
  Result = Data.define(:recipe, :text, :site_name, :title) do
    def complete? = recipe.present? && recipe[:ingredients].any? && recipe[:steps].any?
  end

  def initialize(html, url:)
    @doc = Nokogiri::HTML(html)
    @url = url
  end

  def call
    recipe = structured_recipe
    Result.new(recipe: recipe, text: visible_text, site_name: site_name, title: recipe&.dig(:name) || page_title)
  end

  private

  def structured_recipe
    node = json_ld_nodes.find { |n| types(n).include?("Recipe") }
    return unless node

    {
      name: plain(node["name"]),
      description: plain(node["description"]),
      ingredients: Array(node["recipeIngredient"] || node["ingredients"]).map { plain(_1) }.compact_blank,
      steps: steps(node["recipeInstructions"]),
      hints: [ node["recipeCategory"], node["recipeCuisine"], node["keywords"] ].flat_map { list(_1) }.uniq
    }
  end

  # Every JSON-LD object on the page, including those inside arrays and @graph.
  def json_ld_nodes
    @doc.css('script[type="application/ld+json"]').flat_map do |script|
      flatten_nodes(JSON.parse(script.text))
    rescue JSON::ParserError
      []
    end
  end

  def flatten_nodes(value)
    case value
    when Array then value.flat_map { flatten_nodes(_1) }
    when Hash then [ value, *flatten_nodes(value["@graph"]) ]
    else []
    end
  end

  def types(node) = Array(node["@type"]).map { _1.to_s.delete_prefix("schema:").delete_prefix("http://schema.org/") }

  # Instructions come as one string, a list of strings, HowToStep objects, or HowToSections of those.
  def steps(value)
    case value
    when String then plain(value).to_s.split(/\n+/).map(&:strip).compact_blank
    when Array then value.flat_map { steps(_1) }
    when Hash
      value["itemListElement"] ? steps(value["itemListElement"]) : steps(value["text"] || value["name"])
    else []
    end
  end

  def list(value)
    value.is_a?(String) ? value.split(/[,，、]/).map(&:strip).compact_blank : Array(value).map(&:to_s)
  end

  # Strips any HTML and decodes entities, keeping line breaks from <br> and block tags.
  def plain(value)
    return unless value.is_a?(String)

    fragment = Nokogiri::HTML.fragment(value.gsub(%r{<br\s*/?>|</p>|</li>}i, "\n"))
    fragment.text.gsub(/[ \t ]+/, " ").gsub(/ *\n */, "\n").strip.presence
  end

  def visible_text
    root = @doc.at_css("main, article, [role=main]") || @doc.at_css("body")
    return "" unless root

    root = root.dup
    root.css(NOISE).each(&:remove)
    root.css("br, p, div, li, h1, h2, h3, h4, tr").each { |el| el.add_next_sibling("\n") }
    root.text.gsub(/[ \t ]+/, " ").gsub(/\s*\n\s*/, "\n").strip.first(MAX_TEXT_CHARS)
  end

  def page_title
    title = @doc.at_css('meta[property="og:title"]')&.[]("content") || @doc.at_css("title")&.text
    plain(title)
  end

  def site_name
    meta = @doc.at_css('meta[property="og:site_name"]')&.[]("content")&.strip
    return meta if meta.present?

    RecipeLink.site_name(@url)
  end
end
