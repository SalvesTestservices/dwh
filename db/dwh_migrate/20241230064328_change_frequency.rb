class ChangeFrequency < ActiveRecord::Migration[8.0]
  def change
    change_column :dp_pipelines, :frequency, :string
  end
end
