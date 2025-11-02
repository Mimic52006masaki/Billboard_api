class Api::V1::SongsController < ApplicationController
  def index
    songs = Song.where(chart_date: params[:chart_date] || Date.today).order(:rank)
    render json: songs
  end

  def show
    song = Song.find(params[:id])
    render json: song
  end
end