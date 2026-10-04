# The address of the exact page a recipe came from (GLOSSARY: Recipe link), in one canonical form, so the same
# page is recognised however it was copied: tracking parameters and #fragments dropped, scheme and host
# lowercased, and 下厨房's desktop and mobile addresses unified.
module RecipeLink
  TRACKING_PARAM = /\A(utm_\w+|fbclid|gclid)\z/
  XIACHUFANG_HOSTS = %w[xiachufang.com www.xiachufang.com m.xiachufang.com].freeze

  # Blank → nil. Anything that isn't a parsable http(s) URL is returned stripped, for validation to reject.
  def self.normalize(url)
    url = url.to_s.strip
    return if url.empty?

    uri = URI.parse(url)
    return url unless uri.is_a?(URI::HTTP) && uri.host

    uri.scheme = uri.scheme.downcase
    uri.host = uri.host.downcase
    if XIACHUFANG_HOSTS.include?(uri.host)
      uri = URI::HTTPS.build(host: "www.xiachufang.com", path: uri.path, query: uri.query)
    end
    # "#comments" only scrolls the page, but "#/recipe/12" (or "#!…") is how some sites address the recipe itself.
    uri.fragment = nil unless uri.fragment.to_s.start_with?("/", "!")
    uri.query = without_tracking(uri.query)
    uri.to_s
  rescue URI::InvalidURIError, ArgumentError
    url
  end

  def self.without_tracking(query)
    return if query.blank?

    # Filter the raw "name=value" parts, so everything else stays exactly as written (e.g. a bare "?12345").
    kept = query.split("&").reject { |part| URI.decode_www_form_component(part.split("=", 2).first.to_s).match?(TRACKING_PARAM) }
    kept.empty? ? nil : kept.join("&")
  end
  private_class_method :without_tracking
end
