class ScrapeJob < ApplicationJob
  queue_as :default

  def perform
    scraped_songs = BillboardScraper.scrape
    new_fingerprint = generate_fingerprint(scraped_songs)

    latest_chart = Chart.order(chart_date: :desc).first

    if latest_chart&.fingerprint == new_fingerprint
      Rails.logger.info "ランキングに変更なし。保存スキップ"
      return 0
    end

    Chart.transaction do
      chart = Chart.create!(
        chart_date: Date.current,
        fingerprint: new_fingerprint
      )

      scraped_songs.each do |song_data|
        chart.songs.create!(
          rank: song_data[:rank],
          title: song_data[:title],
          artist: song_data[:artist],
          last_week: song_data[:last_week]
        )
      rescue => e
        Rails.logger.warn("Failed to save song rank #{song_data[:rank]}: #{e.message}")
        next
      end
    end
    scraped_songs.size
  end

  private

  def generate_fingerprint(songs)
    sorted_data = songs.sort_by { |s| s[:rank] }.map { |s| "#{s[:rank]}:#{s[:title]}" }.join('|')
    Digest::SHA256.hexdigest(sorted_data)
  end
end