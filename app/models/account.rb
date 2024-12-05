class Account
  include ActiveModel::Model

  attr_accessor :id, :name, :is_holding, :original_id

  ACCOUNTS = [
    { id: 1, name: 'QDat Holding', original_id: 4, is_holding: false },
    { id: 2, name: 'Salves', original_id: 2, is_holding: false },
    { id: 3, name: 'Test Crew IT', original_id: 6, is_holding: false },
    { id: 4, name: 'Valori', original_id: 8, is_holding: false },
    { id: 5, name: 'Cerios', original_id: 1, is_holding: true }
  ].freeze

  def self.all
    ACCOUNTS.map { |account| new(account) }
  end

  def self.find(id)
    account = ACCOUNTS.find { |a| a[:id] == id }
    new(account) if account
  end

  def self.where(conditions)
    results = ACCOUNTS.select do |account|
      conditions.all? { |key, value| account[key] == value }
    end
    results.map { |account| new(account) }
  end

  def self.order(attribute)
    sorted_accounts = ACCOUNTS.sort_by { |account| account[attribute] }
    sorted_accounts.map { |account| new(account) }
  end
end
