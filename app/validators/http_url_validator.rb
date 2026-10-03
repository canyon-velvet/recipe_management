# Accepts only a whole http(s) URL. The regexp is anchored, so a value that merely contains one
# (e.g. "javascript:alert(1)//http://x.com") is rejected before it can be rendered as a link.
class HttpUrlValidator < ActiveModel::EachValidator
  FORMAT = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/

  def validate_each(record, attribute, value)
    record.errors.add(attribute, :invalid) unless FORMAT.match?(value.to_s)
  end
end
