module Datalab
  module Calculators
    class ProjectCalculator < BaseCalculator
      class << self
        def calculate_start_date(record)
          calculate_date(record.start_date)
        end

        def calculate_end_date(record)
          calculate_date(record.end_date)
        end

        def calculate_expected_end_date(record)
          calculate_date(record.expected_end_date)
        end

        def calculate_nr_active_projectusers(record)
          nr_active_projectusers = 0

          projectusers = Dwh::FactProjectuser.where(project_id: record.id)
          unless projectusers.blank?
            projectusers.each do |projectuser|
              start_date = nil
              end_date = nil

              unless projectuser.start_date.blank?
                if projectuser.start_date.to_s.length == 7
                  start_date = Date.new(projectuser.start_date.to_s[3..6].to_i, projectuser.start_date.to_s[1..2].to_i, projectuser.start_date.to_s[0].to_i)
                else
                  start_date = Date.new(projectuser.start_date.to_s[4..7].to_i, projectuser.start_date.to_s[2..3].to_i, projectuser.start_date.to_s[0..1].to_i)
                end
              end

              unless projectuser.end_date.blank?
                if projectuser.end_date.to_s.length == 7
                  end_date = Date.new(projectuser.end_date.to_s[3..6].to_i, projectuser.end_date.to_s[1..2].to_i, projectuser.end_date.to_s[0].to_i)
                else
                  end_date = Date.new(projectuser.end_date.to_s[4..7].to_i, projectuser.end_date.to_s[2..3].to_i, projectuser.end_date.to_s[0..1].to_i)
                end
              end

              if (start_date.blank? || start_date <= Date.today) && (end_date.blank? || end_date >= Date.today)
                nr_active_projectusers += 1
              end
            end
          end
          nr_active_projectusers
        end
      end
    end
  end
end
