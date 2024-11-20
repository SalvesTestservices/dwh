class LucanetTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :lucanet_transactions do |t|
      t.string    :uid
      t.string    :period
      t.integer   :month
      t.integer   :year
      t.integer   :quarter
      t.string    :currency
      t.decimal   :amount, precision: 10, scale: 2
      t.datetime  :export_timestamp

      t.string    :adjustment_level_name
      t.string    :adjustment_level_type
      t.string    :adjustment_level_order

      t.string    :data_level_name
      t.string    :data_level_type
      t.integer   :data_level_period_from
      t.integer   :data_level_period_to

      t.string    :partner_id
      t.string    :partner_name

      t.string    :organisation_element_id
      t.string    :organisation_element_name
      t.string    :organisation_accounting_or_consolidation_area

      t.string    :transaction_structure_type_id
      t.string    :transaction_type_name
      t.string    :transaction_type_type

      t.string    :account_report_element_id
      t.string    :account_name
      t.string    :account_balance_type
      t.string    :account_level_1
      t.string    :account_level_2
      t.string    :account_level_3
      t.string    :account_level_4
      t.string    :account_level_5
      t.string    :account_level_6

      t.timestamps
    end

    add_index :lucanet_transactions, [:uid], unique: true
    add_index :lucanet_transactions, :period
    add_index :lucanet_transactions, :month
    add_index :lucanet_transactions, :year
    add_index :lucanet_transactions, :quarter

    add_index :lucanet_transactions, :adjustment_level_name
    add_index :lucanet_transactions, :adjustment_level_type
    add_index :lucanet_transactions, :adjustment_level_order

    add_index :lucanet_transactions, :data_level_name
    add_index :lucanet_transactions, :data_level_type
    add_index :lucanet_transactions, :data_level_period_from
    add_index :lucanet_transactions, :data_level_period_to

    add_index :lucanet_transactions, :partner_id

    add_index :lucanet_transactions, :organisation_element_id

    add_index :lucanet_transactions, :transaction_structure_type_id
    add_index :lucanet_transactions, :transaction_type_name
    add_index :lucanet_transactions, :transaction_type_type

    add_index :lucanet_transactions, :account_report_element_id
    add_index :lucanet_transactions, :account_name
    add_index :lucanet_transactions, :account_balance_type
    add_index :lucanet_transactions, :account_level_1
    add_index :lucanet_transactions, :account_level_2
    add_index :lucanet_transactions, :account_level_3
    add_index :lucanet_transactions, :account_level_4
    add_index :lucanet_transactions, :account_level_5
    add_index :lucanet_transactions, :account_level_6

  end
end