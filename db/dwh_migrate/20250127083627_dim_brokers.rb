class DimBrokers < ActiveRecord::Migration[8.0]
  def change
    create_table :dim_brokers do |t|
      t.string  :name
      t.integer :backbone_id

      t.timestamps
    end
    add_index :dim_brokers, [:name], unique: true
    add_index :dim_brokers, :backbone_id
  end
end
