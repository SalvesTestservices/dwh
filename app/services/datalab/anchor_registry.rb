module Datalab
  class AnchorRegistry
    class << self
      def available_anchors
        {
          users: {
            name: 'Users',
            service: Datalab::Anchors::UsersAnchor
          }
          # Add more anchors as needed:
          # customers: {
          #   name: 'Customers',
          #   service: Datalab::Anchors::CustomersAnchor
          # }
        }
      end

      def get_anchor(anchor_type)
        available_anchors[anchor_type.to_sym]
      end
    end
  end
end