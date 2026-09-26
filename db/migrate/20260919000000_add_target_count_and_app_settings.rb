class AddTargetCountAndAppSettings < ActiveRecord::Migration[8.0]
  def change
    # 60 was the only supported length until now, so every existing run keeps it.
    add_column :update_runs, :target_count, :integer, default: 60, null: false

    create_table :app_settings do |t|
      t.integer :target_count, default: 60, null: false
      t.timestamps
    end
  end
end
