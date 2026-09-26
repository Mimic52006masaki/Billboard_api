class Api::V1::UpdateItemsController < ApplicationController
  before_action :set_run_and_item

  def update
    unless UpdateItem::STATUSES.include?(params[:status])
      return render json: { error: "invalid_status" }, status: :unprocessable_entity
    end

    @item.update!(item_params)
    @run.update!(
      status: %w[held mismatch].include?(@item.status) ? "blocked" : "running",
      error_code: @item.error_code,
      error_message: @item.error_message
    )
    render json: @item.as_json.merge(title: @item.song.title, artist: @item.song.artist)
  end

  private

  def set_run_and_item
    @run = UpdateRun.find(params[:update_run_id])
    @item = @run.update_items.find(params[:id])
  end

  def item_params
    params.permit(:status, :apple_title, :apple_artist, :apple_kind, :apple_url, :match_result, :error_code, :error_message)
  end
end
