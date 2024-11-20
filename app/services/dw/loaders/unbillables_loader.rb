class Dw::Loaders::UnbillablesLoader
  def init
  end

  def load_data(account)
    dim_account = Dw::DimAccount.find_by(original_id: account.id)

    unbillables = Dw::EtlStorage.where(account_id: account.id, identifier: "unbillables", etl: "transform")
    unless unbillables.blank?
      unbillables.each do |unbillable|
        Dw::DimUnbillable.upsert({ account_id: dim_account.id, original_id: unbillable.data['original_id'], name: unbillable.data['name'], 
          name_short: unbillable.data['name_short'] }, unique_by: [:account_id, :original_id])

        unbillable.destroy
      end
    end
  end
end