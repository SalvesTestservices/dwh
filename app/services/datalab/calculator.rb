module Datalab
  class Calculator
    def initialize(anchor_type)
      @anchor_type = anchor_type
      @anchor_service = AnchorRegistry.get_anchor(anchor_type)[:service]
    end

    def calculate_for_record(record, attribute_id)
      attribute = @anchor_service.available_attributes[attribute_id.to_sym]
      case attribute[:calculation_type]
      when "direct"
        record.send(attribute_id)
      when "translation"
        record.send(attribute[:method])
      when "complex"
        instance_exec(record, &attribute[:compute])
      else
        nil
      end
    rescue => e
      Rails.logger.error "Error calculating #{attribute_id} for #{record.class}##{record.id}: #{e.message}"
      nil
    end
  end
end