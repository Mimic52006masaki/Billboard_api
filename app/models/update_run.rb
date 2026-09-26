class UpdateRun < ApplicationRecord
  STATUSES = %w[ready running blocked mismatch completed].freeze

  belongs_to :chart
  has_many :update_items, -> { order(:rank) }, dependent: :destroy

  validates :target_date, :playlist_name, presence: true
  validates :target_date, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :target_count, inclusion: { in: AppSetting::TARGET_RANGE }
  validates :verified_prefix, inclusion: { in: 0..AppSetting::TARGET_RANGE.max }
  validates :playlist_count, numericality: { greater_than_or_equal_to: 0 }

  def next_item
    update_items.find_by(rank: verified_prefix + 1)
  end

  # Growing a run adds the missing ranks from its own chart; shrinking removes
  # only ranks that are not verified yet, so a length change can never discard
  # a position that is already confirmed in the real playlist.
  def retarget!(count)
    raise ArgumentError, "#{verified_prefix}位まで検証済みのため#{count}曲には減らせません" if count < verified_prefix
    raise ArgumentError, "曲数は#{AppSetting::TARGET_RANGE.min}〜#{AppSetting::TARGET_RANGE.max}の範囲で指定してください" unless AppSetting::TARGET_RANGE.cover?(count)
    return self if count == target_count

    transaction do
      update_items.where("rank > ?", count).destroy_all
      chart.songs.where(rank: (update_items.count + 1)..count).order(:rank).each do |song|
        update_items.create!(song: song, rank: song.rank)
      end
      update!(
        target_count: count,
        status: status == "completed" && verified_prefix < count ? "running" : status,
        completed_at: status == "completed" && verified_prefix < count ? nil : completed_at
      )
    end
    reload
  end

  def apply_verification!(rows:, playlist_url: nil)
    result = PlaylistVerifier.new(update_run: self, rows: rows).call
    transaction do
      update!(
        playlist_url: playlist_url.presence || self.playlist_url,
        playlist_count: result[:count],
        verified_prefix: result[:verified_prefix],
        status: result[:clean_complete] ? "completed" : result[:status],
        error_code: result[:error_code],
        error_message: result[:error_message],
        completed_at: result[:clean_complete] ? Time.current : nil
      )
      update_items.each do |item|
        verified = item.rank <= result[:verified_prefix]
        item.update!(
          status: verified ? "verified" : "pending",
          verified_at: verified ? Time.current : nil,
          error_code: verified ? nil : item.error_code,
          error_message: verified ? nil : item.error_message
        )
      end
    end
    result
  end
end
