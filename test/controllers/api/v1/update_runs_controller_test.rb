require "test_helper"

class Api::V1::UpdateRunsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @chart = Chart.create!(chart_date: Date.new(2026, 9, 6), fingerprint: SecureRandom.hex)
    100.times do |index|
      @chart.songs.create!(rank: index + 1, title: "Song #{index + 1}", artist: "Artist #{index + 1}", chart_date: @chart.chart_date)
    end
  end

  test "creates one resumable run with sixty items" do
    assert_difference({ "UpdateRun.count" => 1, "UpdateItem.count" => 60 }) do
      post "/api/v1/update_runs", params: { target_date: "2026-09-06" }, as: :json
    end
    assert_response :created
    payload = response.parsed_body
    assert_equal "ビルボード(2026-09-06)", payload["playlist_name"]
    assert_equal 60, payload["items"].length

    post "/api/v1/update_runs", params: { target_date: "2026-09-06" }, as: :json
    assert_response :ok
    assert_equal 1, UpdateRun.where(target_date: "2026-09-06").count
  end

  test "recomputes progress from live playlist rows" do
    post "/api/v1/update_runs", params: { target_date: "2026-09-06" }, as: :json
    run_id = response.parsed_body["id"]
    post "/api/v1/update_runs/#{run_id}/verify", params: {
      playlist_url: "https://music.apple.com/jp/playlist/example/pl.test",
      rows: [{ title: "Song 1", artist: "Artist 1" }, { title: "Song 2", artist: "Artist 2" }]
    }, as: :json
    assert_response :ok
    assert_equal 2, response.parsed_body.dig("run", "verified_prefix")
    assert_equal "verified", response.parsed_body.dig("run", "items", 1, "status")
  end

  test "clears a previous item error after live verification succeeds" do
    post "/api/v1/update_runs", params: { target_date: "2026-09-06" }, as: :json
    run = UpdateRun.find(response.parsed_body["id"])
    run.update_items.find_by!(rank: 1).update!(
      status: "held",
      error_code: "playlist_url_invalid",
      error_message: "old error"
    )

    post "/api/v1/update_runs/#{run.id}/verify", params: {
      playlist_url: "https://music.apple.com/us/library/playlist/p.example",
      rows: [{ title: "Song 1", artist: "Artist 1" }]
    }, as: :json

    assert_response :ok
    item = response.parsed_body.dig("run", "items", 0)
    assert_equal "verified", item["status"]
    assert_nil item["error_code"]
    assert_nil item["error_message"]
  end
end
