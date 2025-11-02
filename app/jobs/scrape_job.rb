class ScrapeJob < ApplicationJob
  queue_as :default

  def perform(chart_date = Date.today)
    results = BillboardScraper.scrape
    imported = 0

    Song.transaction do
      results.each do |row|
        song = Song.find_or_initialize_by(rank: row[:rank], chart_date: chart_date)
        song.assign_attributes(
          title: row[:title],
          artist: row[:artist],
          last_week: row[:last_week]
        )
        song.save!
        imported += 1
      rescue => e
        Rails.logger.warn("Failed to save song rank #{row[:rank]}: #{e.message}")
        next
      end
    end
    imported
  end        
end