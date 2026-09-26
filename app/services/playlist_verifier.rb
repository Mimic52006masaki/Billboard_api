class PlaylistVerifier
  def initialize(update_run:, rows:)
    @run = update_run
    @rows = Array(rows).map(&:with_indifferent_access)
  end

  def call
    expected = @run.update_items.includes(:song).to_a
    prefix = 0
    mismatch = nil

    @rows.first(target_count).each_with_index do |row, index|
      item = expected[index]
      break unless item

      if TrackNormalizer.forbidden_version?(row[:title]) || !TrackNormalizer.same_track?(
        expected_title: item.song.title,
        expected_artist: item.song.artist,
        actual_title: row[:title],
        actual_artist: row[:artist],
        actual_url: row[:url]
      )
        mismatch = index + 1
        break
      end
      prefix += 1
    end

    duplicate = normalized_rows.tally.find { |_key, count| count > 1 }&.first
    clean_complete = @rows.length == target_count && prefix == target_count && duplicate.nil?
    error_code = if duplicate
      "duplicate"
    elsif mismatch
      "order_or_version_mismatch"
    elsif @rows.length > prefix
      "non_contiguous_playlist"
    end

    {
      count: @rows.length,
      verified_prefix: prefix,
      clean_complete: clean_complete,
      status: error_code ? "mismatch" : "running",
      error_code: error_code,
      error_message: error_code && "Apple Musicプレイリストを#{prefix + 1}位から確認してください"
    }
  end

  private

  def target_count
    @run.target_count
  end

  def normalized_rows
    @rows.map { |row| [TrackNormalizer.normalize(row[:title]), TrackNormalizer.normalize(row[:artist])] }
  end
end
