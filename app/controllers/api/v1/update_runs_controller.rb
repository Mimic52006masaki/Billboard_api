class Api::V1::UpdateRunsController < ApplicationController
  before_action :set_run, only: [:show, :verify, :destroy]

  def index
    render json: UpdateRun.order(created_at: :desc).limit(20).map { |run| serialize(run, include_items: false) }
  end

  def show
    render json: serialize(@run, include_items: true)
  end

  # 実行履歴から不要な実行（更新する気のない当日空ドラフト等）を削除する。
  # update_items は has_many の dependent: :destroy でまとめて消える。
  # Apple Music 側の実プレイリストには一切触れない。
  def destroy
    @run.destroy!
    head :no_content
  end

  def create
    target_date = Date.iso8601(params[:target_date].presence || Time.zone.today.iso8601)
    chart = Chart.order(chart_date: :desc).first
    return render json: { error: "latest_chart_missing" }, status: :unprocessable_entity unless chart
    return render json: { error: "chart_requires_100_songs", count: chart.songs.count }, status: :unprocessable_entity unless chart.songs.count == 100

    run = UpdateRun.find_or_initialize_by(target_date: target_date)
    created = run.new_record?
    if created
      target_count = AppSetting.current.target_count
      run.assign_attributes(
        chart: chart,
        playlist_name: "ビルボード(#{target_date})",
        status: "ready",
        target_count: target_count,
        started_at: Time.current
      )
      run.transaction do
        run.save!
        chart.songs.order(:rank).limit(target_count).each do |song|
          run.update_items.create!(song: song, rank: song.rank)
        end
      end
    end
    render json: serialize(run.reload, include_items: true), status: created ? :created : :ok
  rescue Date::Error
    render json: { error: "invalid_target_date" }, status: :unprocessable_entity
  end

  def verify
    rows = params.require(:rows).map { |row| row.permit(:title, :artist, :url).to_h }
    result = @run.apply_verification!(rows: rows, playlist_url: params[:playlist_url])
    render json: { verification: result, run: serialize(@run.reload, include_items: true) }
  end

  private

  def set_run
    @run = UpdateRun.find(params[:id])
  end

  def serialize(run, include_items:)
    payload = run.as_json(except: [:updated_at]).merge(
      "next_rank" => run.verified_prefix < run.target_count ? run.verified_prefix + 1 : nil,
      "checkpoint_due" => run.verified_prefix.positive? && (run.verified_prefix % 10).zero?
    )
    return payload unless include_items

    payload.merge("items" => run.update_items.includes(:song).map do |item|
      item.as_json(except: [:created_at, :updated_at]).merge(
        "title" => item.song.title,
        "artist" => item.song.artist
      )
    end)
  end
end
