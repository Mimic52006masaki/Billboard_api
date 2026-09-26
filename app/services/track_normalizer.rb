require "uri"

module TrackNormalizer
  FORBIDDEN_VERSION = /(?:\(|\[|\b)(live|remix|mixed|acoustic|piano|edit|booster version|instrumental|karaoke|commentary)\b/i

  # Billboard credits collaborations as "Lead With B & C", "Lead Featuring B",
  # "Lead, B & C" or "Lead X B". Apple Music often credits fewer artists, or
  # localises some of them, so the lead artist is the only part we can rely on.
  # "and" is deliberately absent: it appears inside real names (Dexter And The
  # Moonrocks), and " x " needs the surrounding spaces so X Ambassadors survives.
  COLLABORATION_SPLIT = /\s+(?:featuring|feat\.?|with|vs\.?|x)\s+|\s*[&,]\s*/i
  JOIN_WORDS = %w[and feat featuring with vs x].freeze

  module_function

  def normalize(value)
    value.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").tr("‘’", "''").downcase.gsub(/[^a-z0-9]+/, " ").strip
  end

  def display_equal?(left, right)
    left.to_s.unicode_normalize(:nfkc).strip.gsub(/\s+/, " ") == right.to_s.unicode_normalize(:nfkc).strip.gsub(/\s+/, " ")
  end

  def forbidden_version?(title)
    title.to_s.match?(FORBIDDEN_VERSION)
  end

  def same_track?(expected_title:, expected_artist:, actual_title:, actual_artist:, actual_url: nil)
    exact = normalize(expected_title) == normalize(actual_title) && artist_match?(expected_artist, actual_artist)
    matched = exact || known_variant_match?(
      expected_title: expected_title,
      actual_title: actual_title,
      actual_artist: actual_artist
    )
    matched && known_url_matches?(expected_title: expected_title, actual_title: actual_title, actual_artist: actual_artist, actual_url: actual_url)
  end

  def known_variant_match?(expected_title:, actual_title:, actual_artist:)
    known_variants.any? do |variant|
      normalize(variant.fetch("billboard_title")) == normalize(expected_title) &&
        variant.fetch("apple_titles", []).any? { |title| normalize(title) == normalize(actual_title) } &&
        (variant.fetch("apple_artists", []).empty? || variant.fetch("apple_artists").any? { |artist| artist_match?(artist, actual_artist) })
    end
  end

  def known_url_matches?(expected_title:, actual_title:, actual_artist:, actual_url:)
    constrained = known_variants.select do |variant|
      normalize(variant.fetch("billboard_title")) == normalize(expected_title) &&
        variant.fetch("apple_titles", []).any? { |title| normalize(title) == normalize(actual_title) } &&
        (variant.fetch("apple_artists", []).empty? || variant.fetch("apple_artists").any? { |artist| artist_match?(artist, actual_artist) }) &&
        variant.fetch("apple_urls", []).any?
    end
    return true if constrained.empty?

    actual_track_id = track_id(actual_url)
    actual_track_id && constrained.any? do |variant|
      variant.fetch("apple_urls").any? { |url| track_id(url) == actual_track_id }
    end
  end

  def track_id(value)
    uri = URI.parse(value.to_s)
    query_id = URI.decode_www_form(uri.query.to_s).to_h["i"]
    return query_id unless query_id.to_s.empty?

    uri.path[%r{/song/(?:[^/]+/)?(\d+)$}, 1]
  rescue URI::InvalidURIError
    nil
  end

  def known_variants
    @known_variants ||= YAML.safe_load_file(Rails.root.join("config/known_track_variants.yml"), aliases: false)
  end

  def artist_match?(expected, actual)
    return true if display_equal?(expected, actual)
    return true if tokens_contained?(expected, actual)

    # Fall back to the lead artist alone: a fuller Billboard credit must not be
    # harder to match than the truncated one the scraper used to produce.
    lead = lead_artist(expected)
    return true if lead != expected.to_s && tokens_contained?(lead, actual)

    [expected.to_s, lead].uniq.any? do |name|
      known_artist_aliases.fetch(name, []).any? { |artist| display_equal?(artist, actual) }
    end
  end

  def lead_artist(value)
    value.to_s.split(COLLABORATION_SPLIT).first.to_s.strip
  end

  def tokens_contained?(expected, actual)
    expected_tokens = normalize(expected).split.reject { |part| JOIN_WORDS.include?(part) }
    actual_tokens = normalize(actual).split
    expected_tokens.any? && expected_tokens.all? { |part| actual_tokens.include?(part) }
  end

  def known_artist_aliases
    @known_artist_aliases ||= YAML.safe_load_file(Rails.root.join("config/known_artist_aliases.yml"), aliases: false)
  end
end
