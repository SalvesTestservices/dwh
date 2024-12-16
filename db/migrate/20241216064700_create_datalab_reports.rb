class CreateDatalabReports < ActiveRecord::Migration[7.1]
  def change
    create_table :datalab_reports do |t|
      t.string :name
      t.string :description
      t.string :anchor_type
      t.json :column_config
      t.references :user, foreign_key: true
      t.boolean :is_public, default: false
      
      t.timestamps
    end
    
    add_index :datalab_reports, [:user_id, :name]
    add_index :datalab_reports, :anchor_type
  end
end
