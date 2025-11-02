class Song < ApplicationRecord
  validates :rank, presence: true, uniqueness: {scope: :chart_date}
  validates :title, :artist, presence: true
end
