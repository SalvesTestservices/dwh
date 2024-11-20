class AddMonthAndYearToOpenInvoicing < ActiveRecord::Migration[7.1]
  def change
    add_column :bb_open_invoicing_overviews, :month, :integer
    add_column :bb_open_invoicing_overviews, :year, :integer
    add_index :bb_open_invoicing_overviews, [:month, :year]
  end
end
