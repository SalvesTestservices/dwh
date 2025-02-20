module Datalab
  class AnchorRegistry
    class << self
      def available_anchors
        {
          projects: {
            name: 'Klanten & Projecten',
            service: Datalab::Anchors::ProjectsAnchor
          },
          users: {
            name: 'Medewerkers',
            service: Datalab::Anchors::UsersAnchor
          },
          hours: {
            name: 'Uren',
            service: Datalab::Anchors::HoursAnchor
          }
        }
      end

      def get_anchor(anchor_type)
        available_anchors[anchor_type.to_sym]
      end
    end
  end
end