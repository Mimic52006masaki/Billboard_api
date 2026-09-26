require "test_helper"

class PlaylistVerifierTest < ActiveSupport::TestCase
  setup do
    @chart = Chart.create!(chart_date: Date.new(2026, 9, 5), fingerprint: SecureRandom.hex)
    @run = UpdateRun.create!(chart: @chart, target_date: Date.new(2026, 9, 5), playlist_name: "ビルボード(2026-09-05)")
    3.times do |index|
      song = @chart.songs.create!(rank: index + 1, title: "Song #{index + 1}", artist: "Artist #{index + 1}", chart_date: @chart.chart_date)
      @run.update_items.create!(song: song, rank: index + 1)
    end
  end

  test "finds a continuous prefix" do
    rows = [{ title: "Song 1", artist: "Artist 1" }, { title: "Song 2", artist: "Artist 2" }]
    result = PlaylistVerifier.new(update_run: @run, rows: rows).call
    assert_equal 2, result[:verified_prefix]
    assert_nil result[:error_code]
  end

  test "stops at an order mismatch" do
    rows = [{ title: "Song 1", artist: "Artist 1" }, { title: "Wrong", artist: "Artist 2" }]
    result = PlaylistVerifier.new(update_run: @run, rows: rows).call
    assert_equal 1, result[:verified_prefix]
    assert_equal "order_or_version_mismatch", result[:error_code]
  end

  test "detects duplicates" do
    rows = [{ title: "Song 1", artist: "Artist 1" }, { title: "Song 1", artist: "Artist 1" }]
    result = PlaylistVerifier.new(update_run: @run, rows: rows).call
    assert_equal "duplicate", result[:error_code]
  end

  test "accepts a configured official title variant" do
    song = @run.update_items.find_by!(rank: 1).song
    song.update!(title: "I Knew It, I Knew You", artist: "Taylor Swift")
    rows = [{ title: 'I Knew It, I Knew You (From "Toy Story 5")', artist: "テイラー・スウィフト" }]
    result = PlaylistVerifier.new(update_run: @run, rows: rows).call
    assert_equal 1, result[:verified_prefix]
    assert_nil result[:error_code]
  end

  test "rejects a configured variant when its track ID is not allowed" do
    song = @run.update_items.find_by!(rank: 1).song
    song.update!(title: "Morning Dew (Donk)", artist: "Beyonce")
    rows = [{ title: "MORNING DEW (DONK)", artist: "Beyoncé", url: "https://music.apple.com/jp/album/bday-20th-anniversary-deluxe-edition/6808332952?i=6808333342" }]
    result = PlaylistVerifier.new(update_run: @run, rows: rows).call
    assert_equal 0, result[:verified_prefix]
    assert_equal "order_or_version_mismatch", result[:error_code]
  end
end
