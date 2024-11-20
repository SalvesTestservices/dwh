class EtlStorages < ActiveRecord::Migration[7.0]
  def change
    create_table :etl_storages do |t|
      t.integer :account_id
      t.string  :identifier
      t.string  :etl
      t.jsonb   :data, default: {}

      t.timestamps
    end
    add_index :etl_storages, :account_id
    add_index :etl_storages, :identifier
    add_index :etl_storages, :etl
  end
end
