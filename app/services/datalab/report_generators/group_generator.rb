module Datalab
  module ReportGenerators
    class GroupGenerator < BaseGenerator
      def generate
        records, _total_count = @anchor_service.fetch_data(
          @params[:filters],
          nil,
          nil
        )

        grouped_records = group_records(records, @params)

        [records, {
          columns: generate_group_columns,
          rows: grouped_records,
          total_count: grouped_records.size,
          current_page: 1,
          items_per_page: grouped_records.size
        }]
      end

      private def group_records(records, params)
        grouped_records = []

        case @report.anchor_type.to_sym
        when :hours
          # First determine unique user ids and months
          user_ids = []
          months = []
          records.each do |record|
            user_ids << record.user_id
            months << extract_month(record.activity_date)
          end

          user_ids = user_ids.uniq
          months = months.uniq.sort

          # Now iterate through each unique user id and month
          user_ids.each do |user_id|
            months.each do |month|
              total_hours = 0.0

              # Find matching records for this user and month
              matching_records = records.select do |record|
                extracted_month = extract_month(record.activity_date)
                record.user_id == user_id && extracted_month == month
              end

              # Skip if no matching records found
              next if matching_records.empty?

              # Take the first record to get the common attributes
              first_record = matching_records.first
              dim_account = Dwh::DimAccount.find_by(id: first_record.account_id)
              dim_company = Dwh::DimCompany.find_by(id: first_record.company_id)
              dim_user = Dwh::DimUser.find_by(id: first_record.user_id)

              # Calculate total hours
              total_hours = matching_records.sum { |record| record.hours.to_f }

              # Create grouped record with keys matching column IDs
              grouped_record = {
                "full_name" => dim_user&.full_name,
                "label" => dim_account&.name,
                "unit" => dim_company&.name,
                "month" => month_name(month),
                "year" => extract_year(first_record.activity_date),
                "hours_ovb" => total_hours.round(1)
              }

              grouped_records << grouped_record
            end
          end
        when :projects
        when :users
        end
        grouped_records
      end

      private def month_name(month_number)
        return '' if month_number.nil?

        # Remove leading zeros from month_number
        month_number = month_number.to_s.sub(/^0+/, '').to_i
        
        month_names = {
          1 => 'januari',
          2 => 'februari',
          3 => 'maart',
          4 => 'april',
          5 => 'mei',
          6 => 'juni',
          7 => 'juli',
          8 => 'augustus',
          9 => 'september',
          10 => 'oktober',
          11 => 'november',
          12 => 'december'
        }
        
        month_names[month_number] || ''
      end

      def generate_group_columns
        case @report.anchor_type.to_sym
        when :hours
          [
            { id: 'full_name', name: 'Naam medewerker' },
            { id: 'label', name: 'Label' },
            { id: 'unit', name: 'Unit' },
            { id: 'month', name: 'Maand' },
            { id: 'year', name: 'Jaar' },
            { id: 'hours_ovb', name: 'OVB' }
          ]
        when :projects
        when :users
        end
      end

      def include_month_grouping?
        @report.column_config.dig('group_by', 'month').present?
      end

      def include_company_grouping?
        @report.column_config.dig('group_by', 'company').present?
      end

      def extract_month(original_date)
        date_str = original_date.to_s
        month = if date_str.length == 7
          date_str[1..2]  # For 7-digit format
        else
          date_str[2..3]  # For 8-digit format (DDMMYYYY)
        end
        month.rjust(2, '0')  # Ensure two digits with leading zero if needed
      end

      def extract_year(original_date)
        date_str = original_date.to_s
        year = if date_str.length == 7
          date_str[3..6]  # For 7-digit format
        else
          date_str[4..7]  # For 8-digit format (DDMMYYYY)
        end
        year.length == 3 ? "2#{year}" : year  # Ensure full year format
      end
    end
  end
end 