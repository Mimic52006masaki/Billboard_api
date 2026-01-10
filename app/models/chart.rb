class Chart < ApplicationRecord
  has_many :songs, dependent: :destroy
end
