class UpdateItem < ApplicationRecord
  STATUSES = %w[pending candidate_ready adding verified held mismatch].freeze

  belongs_to :update_run
  belongs_to :song

  validates :rank, inclusion: { in: 1..AppSetting::TARGET_RANGE.max }, uniqueness: { scope: :update_run_id }
  validates :status, inclusion: { in: STATUSES }
end
