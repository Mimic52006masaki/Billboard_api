module Api
  module V1
    class SettingsController < ApplicationController
      def show
        render json: { target_count: AppSetting.current.target_count }
      end

      # The length is a single app-wide setting, so changing it also resizes the
      # run in progress. A run that is already verified past the new length is
      # left untouched and the setting is not changed either, so the app and the
      # real playlist never disagree about how long the playlist should be.
      def update
        count = Integer(params.require(:target_count))
        active = UpdateRun.where.not(status: "completed").order(:target_date).last
        ActiveRecord::Base.transaction do
          AppSetting.current.update!(target_count: count)
          active&.retarget!(count)
        end
        render json: { target_count: count, updated_run_id: active&.id }
      rescue ArgumentError, TypeError => e
        render json: { error: "target_count_rejected", message: e.message }, status: :unprocessable_entity
      rescue ActiveRecord::RecordInvalid
        render json: { error: "invalid_target_count", message: "曲数は#{AppSetting::TARGET_RANGE.min}〜#{AppSetting::TARGET_RANGE.max}の範囲で指定してください" }, status: :unprocessable_entity
      end
    end
  end
end
