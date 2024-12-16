class Datalab::Calculator
  def initialize(anchor_type)
    @anchor_service = AnchorRegistry.get_anchor(anchor_type)[:service]
  end

  def calculate_for_record(record, attribute_id)
    method_name = "calculate_#{attribute_id}"
    
    if @anchor_service.respond_to?(method_name)
      @anchor_service.send(method_name, record)
    else
      record.send(attribute_id)
    end
  rescue NoMethodError => e
    Rails.logger.error "Failed to calculate #{attribute_id} for record: #{e.message}"
    nil
  end
end