class Dw::Loaders::CustomersLoader
  def init
  end

  def load_data(account)
    dim_account = Dw::DimAccount.find_by(original_id: account.id)

    customers = Dw::EtlStorage.where(account_id: account.id, identifier: "customers", etl: "transform")
    unless customers.blank?
      customers.each do |customer|
        Dw::DimCustomer.upsert({ account_id: dim_account.id, original_id: customer.data['original_id'], name: customer.data['name'], 
          status: customer.data['status'] }, unique_by: [:account_id, :original_id])

        customer.destroy
      end
    end
  end
end