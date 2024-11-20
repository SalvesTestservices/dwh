class ChangeUidFactTargets < ActiveRecord::Migration[7.1]
  def change
    change_column :fact_targets, :uid, :string
  end
end
