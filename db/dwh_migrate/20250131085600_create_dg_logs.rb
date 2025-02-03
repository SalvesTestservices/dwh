class CreateDgLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :dg_logs do |t|
      t.integer :object_id
      t.string :object_type
      t.integer :user_id
      t.string :action
      t.string :status
      t.string :error_message
      t.string :trigger
      t.string :direction
      
      t.timestamps
    end

    add_index :dg_logs, :object_id
    add_index :dg_logs, :object_type
    add_index :dg_logs, :action
    add_index :dg_logs, :status
    add_index :dg_logs, :user_id
    add_index :dg_logs, :trigger
    add_index :dg_logs, :direction
  end
end 