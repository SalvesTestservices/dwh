class Dwh::Loaders::CustomersLoader
  def init
  end

  def load_data(account)
    dim_account = Dwh::DimAccount.find_by(original_id: account.original_id)

    customers = Dwh::EtlStorage.where(account_id: account.id, identifier: "customers", etl: "transform")
    unless customers.blank?
      customers.each do |customer|
        Dwh::DimCustomer.upsert({ account_id: dim_account.id, original_id: customer.data['original_id'], name: customer.data['name'], 
          status: customer.data['status'] }, unique_by: [:account_id, :original_id])

        customer.destroy
      end
    end
  end
end