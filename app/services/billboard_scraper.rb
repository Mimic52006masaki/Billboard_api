require 'httparty'
require 'nokogiri'

class BillboardScraper
  BILLBOARD_URL = 'https://www.billboard.com/charts/hot-100/'

  def self.scrape
    res = HTTParty.get(BILLBOARD_URL, headers: {"User-Agent" => "Mozilla/5.0"}, timeout: 15)
    raise "HTTP error: #{res.code}" unless res.code == 200

    doc = Nokogiri::HTML(res.body)
    rows = doc.css('div.o-chart-results-list-row-container')
    results = []

    rows.each do |row|
      begin
        #rank: try first .c-label that containers number
        rank_span = row.css('span.c-label').find {|s| s.text.strip =~ /^\d+$/}
        next unless rank_span
        rank = rank_span.text.strip.to_i

        title_node = row.css('h3.c-title').first
        title = title_node ? title_node.text.strip : "Unknown Title"

        # artist: try a few patterns
        artist = nil        
        if (a = row.at_css('span.a-no-trucate'))
          # Billboard links only some of the credited artists, so reading the
          # inner <a> drops the rest ("Belly Gang Kushington & 21 Savage" became
          # "21 Savage"). Take the whole span instead and squeeze the markup
          # whitespace the credit string is formatted with.
          artist = a.text.gsub(/\s+/, ' ').strip
        else
          # fallback: second .c-label that isn't rank
          labels = row.css('span.c-label').map {|s| s.text.strip}
          candidate = labels.find {|t| t =~ /[A-Za-z0-9]/ && t.length > 1 && !(t =~ /^\d+$/)}
          artist = candidate || "不明"
        end

        last_week_label = row.css('span.c-label')[2]
        last_week = nil
        if last_week_label
          begin
            last_week = last_week_label.text.strip.to_i
          rescue
            last_week
          end
        end

        results << {
          rank: rank,
          title: title,
          artist: artist,
          last_week: last_week
        }

      rescue => e
        if defined?(Rails)
          Rails.logger.warn("Billboard scrape parse error: #{e.message}")
        else
          warn "Billboard scrape parse error: #{e.message}"
        end
        next      
      end
    end
    results.sort_by { |r| r[:rank]}
  end
end