class CreateCharts < ActiveRecord::Migration[8.0]
  def change
    create_table :charts do |t|
      t.string :fingerprint
      t.date :chart_date

      t.timestamps
    end
  end
end
