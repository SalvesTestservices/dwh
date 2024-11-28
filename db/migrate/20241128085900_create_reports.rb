class CreateReports < ActiveRecord::Migration[7.0]
  def change
    create_table :reports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :filename, null: false
      t.string :format, null: false
      t.string :status, null: false, default: 'pending'

      t.timestamps
    end
  end
end
