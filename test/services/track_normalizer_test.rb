require "test_helper"

class TrackNormalizerTest < ActiveSupport::TestCase
  test "normalizes typography and accents" do
    assert_equal "ahi test", TrackNormalizer.normalize("AHÍ ’ Test")
  end

  test "rejects alternate versions" do
    assert TrackNormalizer.forbidden_version?("Spend Dat (Booster Version)")
    assert TrackNormalizer.forbidden_version?("Raindance Remix")
    refute TrackNormalizer.forbidden_version?("Spend Dat")
  end

  test "matches expected artist tokens" do
    assert TrackNormalizer.same_track?(expected_title: "Jaded", expected_artist: "Koe Wetzel", actual_title: "JADED", actual_artist: "Koe Wetzel & Ella Langley")
  end

  test "matches a configured official title variant" do
    assert TrackNormalizer.same_track?(
      expected_title: "I Knew It, I Knew You",
      expected_artist: "Taylor Swift",
      actual_title: 'I Knew It, I Knew You (From "Toy Story 5")',
      actual_artist: "テイラー・スウィフト"
    )
  end

  test "matches the official Islands In The Stream duet credit" do
    assert TrackNormalizer.same_track?(
      expected_title: "Islands In The Stream",
      expected_artist: "Kenny Rogers",
      actual_title: "Islands In the Stream",
      actual_artist: "Dolly Parton"
    )
  end

  test "matches the official Dai Dai playlist row when Apple Music exposes the lead artist" do
    assert TrackNormalizer.same_track?(
      expected_title: "Dai Dai (FIFA World Cup Official Song 2026)",
      expected_artist: "Shakira",
      actual_title: "Dai Dai",
      actual_artist: "Shakira"
    )
  end

  test "matches the official I Will Always Love You artist variant" do
    assert TrackNormalizer.same_track?(
      expected_title: "I Will Always Love You",
      expected_artist: "Dolly Parton",
      actual_title: "I Will Always Love You",
      actual_artist: "ドリー・パートン",
      actual_url: "https://music.apple.com/jp/album/i-will-always-love-you/282883573?i=282883579"
    )
  end

  test "matches a configured artist alias for an exact title" do
    assert TrackNormalizer.same_track?(
      expected_title: "I Just Might",
      expected_artist: "Bruno Mars",
      actual_title: "I Just Might",
      actual_artist: "ブルーノ・マーズ"
    )

    assert TrackNormalizer.same_track?(
      expected_title: "Drop Dead",
      expected_artist: "Olivia Rodrigo",
      actual_title: "drop dead",
      actual_artist: "オリヴィア・ロドリゴ"
    )

    assert TrackNormalizer.same_track?(
      expected_title: "Some Of Your Love",
      expected_artist: "PARTYNEXTDOOR",
      actual_title: "Some of Your Love",
      actual_artist: "パーティーネクストドア"
    )

    assert TrackNormalizer.same_track?(
      expected_title: "Orbiter",
      expected_artist: "Noah Kahan",
      actual_title: "Orbiter",
      actual_artist: "ノア・カーン"
    )

    assert TrackNormalizer.same_track?(
      expected_title: "Mr. Know It All",
      expected_artist: "Teddy Swims",
      actual_title: "Mr. Know It All",
      actual_artist: "テディ・スウィムズ"
    )

    assert TrackNormalizer.same_track?(
      expected_title: "Cinderella",
      expected_artist: "Mac Miller",
      actual_title: "Cinderella (feat. Ty Dolla $ign)",
      actual_artist: "マック・ミラー"
    )

    assert TrackNormalizer.same_track?(
      expected_title: "Morning Dew (Donk)",
      expected_artist: "Beyonce",
      actual_title: "MORNING DEW (DONK)",
      actual_artist: "Beyoncé",
      actual_url: "https://music.apple.com/jp/album/morning-dew-donk/6787303151?i=6787303156"
    )

    refute TrackNormalizer.same_track?(
      expected_title: "Morning Dew (Donk)",
      expected_artist: "Beyonce",
      actual_title: "MORNING DEW (DONK)",
      actual_artist: "Beyoncé",
      actual_url: "https://music.apple.com/jp/album/bday-20th-anniversary-deluxe-edition/6808332952?i=6808333342"
    )

    refute TrackNormalizer.same_track?(
      expected_title: "Some Of Your Love",
      expected_artist: "PARTYNEXTDOOR",
      actual_title: "Some of Your Love",
      actual_artist: "ザ・ビーチ・ボーイズ"
    )
  end
end
