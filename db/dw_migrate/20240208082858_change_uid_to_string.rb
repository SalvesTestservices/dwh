class ChangeUidToString < ActiveRecord::Migration[7.1]
  def change
    change_column :bb_grouped_work_overviews, :uid, :string
  end
end
