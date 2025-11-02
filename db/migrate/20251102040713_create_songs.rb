class CreateSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :songs do |t|
      t.integer :rank
      t.string :title
      t.string :artist
      t.integer :last_week
      t.date :chart_date

      t.timestamps
    end
  end
end
