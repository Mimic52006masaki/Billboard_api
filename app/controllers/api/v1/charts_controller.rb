class Api::V1::ChartsController < ApplicationController
  def diff_latest
    charts = Chart.order(created_at: :desc).first(2)
    if charts.size < 2
      render json: { error: 'Not enough charts to compare' }, status: :bad_request
      return
    end

    latest_chart, previous_chart = charts
    latest_songs = latest_chart.songs.order(:rank)
    previous_songs = previous_chart.songs.order(:rank)

    def song_key(song)
      "#{song.title}|#{song.artist}"
    end

    latest_keys = latest_songs.map { |s| song_key(s) }
    previous_keys = previous_songs.map { |s| song_key(s) }

    new_keys = latest_keys - previous_keys
    dropped_keys = previous_keys - latest_keys

    new_entries = latest_songs.select { |s| new_keys.include?(song_key(s)) }.map do |s|
      { rank: s.rank, title: s.title, artist: s.artist }
    end

    dropped_entries = previous_songs.select { |s| dropped_keys.include?(song_key(s)) }.map do |s|
      { rank: s.rank, title: s.title, artist: s.artist }
    end

    render json: {
      latest_chart: { chart_date: latest_chart.chart_date },
      previous_chart: { chart_date: previous_chart.chart_date },
      new_entries: new_entries,
      dropped_entries: dropped_entries
    }
  end

  def history
    charts = Chart.order(created_at: :desc).pluck(:chart_date).map { |date| { chart_date: date } }
    render json: charts
  end
end