class Api::V1::SongsController < ApplicationController
  def index
    if params[:chart_date]
      chart = Chart.find_by(chart_date: params[:chart_date])
      if chart
        songs = chart.songs.order(:rank)
        render json: songs
      else
        render json: { error: 'Chart not found' }, status: :not_found
      end
    else
      chart = Chart.order(chart_date: :desc).first
      if chart
        songs = chart.songs.order(:rank)
        render json: songs
      else
        render json: []
      end
    end
  end

  def show
    song = Song.find(params[:id])
    render json: song
  end
end