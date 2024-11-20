class DimProjectusers < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_projectusers do |t|
      t.integer :account_id
      t.integer :original_id
      t.integer :user_id
      t.integer :project_id
      t.date    :start_date
      t.date    :end_date

      t.timestamps
    end
    add_index :dim_projectusers, :account_id
    add_index :dim_projectusers, :original_id
    add_index :dim_projectusers, :user_id
    add_index :dim_projectusers, :project_id
    add_index :dim_projectusers, :start_date
    add_index :dim_projectusers, :end_date
  end
end
