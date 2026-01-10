class Song < ApplicationRecord
  belongs_to :chart
  validates :rank, presence: true
  validates :title, :artist, presence: true
end
