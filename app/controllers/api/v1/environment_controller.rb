class Api::V1::EnvironmentController < ApplicationController
  def show
    chart = Chart.order(chart_date: :desc).first
    render json: {
      api: "ok",
      database: ActiveRecord::Base.connection.active? ? "ok" : "error",
      runtime: File.exist?("/.dockerenv") ? "docker" : "local",
      latest_chart: chart && { id: chart.id, chart_date: chart.chart_date, song_count: chart.songs.count }
    }
  end
end
