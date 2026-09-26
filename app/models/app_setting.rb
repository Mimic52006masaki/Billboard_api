class AppSetting < ApplicationRecord
  TARGET_RANGE = (1..100).freeze

  validates :target_count, inclusion: { in: TARGET_RANGE }

  # The app keeps exactly one settings row. Reading it creates that row on a
  # fresh database so the historical default of 60 applies until it is changed.
  def self.current
    first || create!
  end
end
