class CreateUpdateRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :update_runs do |t|
      t.references :chart, null: false, foreign_key: true
      t.date :target_date, null: false
      t.string :playlist_name, null: false
      t.string :playlist_url
      t.string :status, null: false, default: "ready"
      t.integer :verified_prefix, null: false, default: 0
      t.integer :playlist_count, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at
      t.string :error_code
      t.text :error_message
      t.timestamps
    end

    add_index :update_runs, :target_date, unique: true

    create_table :update_items do |t|
      t.references :update_run, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true
      t.integer :rank, null: false
      t.string :status, null: false, default: "pending"
      t.string :apple_title
      t.string :apple_artist
      t.string :apple_kind
      t.string :apple_url
      t.string :match_result
      t.datetime :verified_at
      t.string :error_code
      t.text :error_message
      t.timestamps
    end

    add_index :update_items, [:update_run_id, :rank], unique: true
  end
end
