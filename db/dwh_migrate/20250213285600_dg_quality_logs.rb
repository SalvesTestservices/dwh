class DgQualityLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :dg_quality_logs do |t|
      t.integer   :quality_check_id
      t.string    :result
      t.string    :error_message
      t.datetime  :read_at
      
      t.timestamps
    end

    add_index :dg_quality_logs, :quality_check_id
    add_index :dg_quality_logs, :result
    add_index :dg_quality_logs, :read_at
  end
end 