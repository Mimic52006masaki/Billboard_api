class ChangeChartIdToNotNullInSongs < ActiveRecord::Migration[8.0]
  def change
    change_column_null :songs, :chart_id, false
  end
end
