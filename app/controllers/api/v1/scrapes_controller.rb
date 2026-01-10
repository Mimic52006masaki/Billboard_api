class Api::V1::ScrapesController < ApplicationController
  def create
    if params[:async] == 'true'
      ScrapeJob.perform_later
      render json: { message: 'Scrape started (background)' }, status: :accepted
    else
      count = ScrapeJob.new.perform
      render json: { message: 'Scrape finished', count: count }, status: :ok
    end
  rescue => e
    render json: { error: e.message }, status: :internal_server_error
  end
end