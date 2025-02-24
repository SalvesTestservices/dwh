module Datalab
  module ReportGenerators
    class GroupGenerator < BaseGenerator
      def generate
        records, _total_count = @anchor_service.fetch_data(
          @params[:filters],
          nil,
          nil
        )
        
        grouped_data = group_records(records)
        rows = generate_group_rows(grouped_data)
        
        [records, {
          columns: generate_group_columns,
          rows: rows,
          total_count: rows.size,
          current_page: 1,
          items_per_page: rows.size
        }]
      end

      private

      def month_name(month_number)
        return '' if month_number.nil?
        
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

      def group_records(records)
        case @report.anchor_type.to_sym
        when :hours
          # First, group records by user_id and month
          records.group_by do |record|
            dim_user = Dwh::DimUser.find_by(id: record.user_id)
            dim_account = Dwh::DimAccount.find_by(id: record.account_id)
            dim_company = Dwh::DimCompany.find_by(id: record.company_id)
            date_str = record.activity_date.to_s
            month = date_str[2..3].to_i  # Extract month from ddmmyyyy
            year = date_str[4..7].to_i   # Extract year from ddmmyyyy
            
            # Create a unique key for each user-month combination
            {
              user_id: record.user_id,
              full_name: dim_user&.full_name,
              label: dim_account&.name,
              unit: dim_company&.name,
              month: month,
              year: year
            }
          end
        when :projects
          records.group_by { |record| [record.customer_id, record.dim_customer&.name] }
        when :users
          group_by_attributes = [:id]
          group_by_attributes << :company_id if include_company_grouping?

          records.group_by do |record|
            group_by_attributes.map do |attr|
              case attr
              when :id
                [record.id, record.full_name]
              when :company_id
                [record.company_id, record.dim_company&.name]
              end
            end.flatten
          end
        end
      end

      def generate_group_rows(grouped_data)
        case @report.anchor_type.to_sym
        when :hours
          grouped_data.map do |group_key, records|
            {
              full_name: group_key[:full_name],
              label: group_key[:label],
              unit: group_key[:unit],
              month: month_name(group_key[:month]),
              year: group_key[:year],
              uren_ouderschapsverlof: records.sum { |r| r.hours.to_f }.round(1)
            }
          end.sort_by { |row| [row[:full_name].to_s, row[:year].to_i, row[:month].to_s] }
        when :projects
          grouped_data.map do |(customer_id, customer_name), records|
            {
              customer_name: customer_name,
              total_projects: records.size,
              active_projects: records.count { |r| r.status == 'active' }
            }
          end
        when :users
          grouped_data.map do |(user_id, full_name), records|
            user = records.first
            {
              full_name: full_name,
              label: user.dim_account&.name,
              unit: user.dim_company&.name,
              role: user.role
            }
          end
        end
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
            { id: 'uren_ouderschapsverlof', name: 'Uren ouderschapsverlof' }
          ]
        when :projects
          [
            { id: 'customer_name', name: 'Klant' },
            { id: 'total_projects', name: 'Aantal projecten' },
            { id: 'active_projects', name: 'Actieve projecten' }
          ]
        when :users
          [
            { id: 'full_name', name: 'Naam medewerker' },
            { id: 'label', name: 'Label' },
            { id: 'unit', name: 'Unit' },
            { id: 'role', name: 'Rol' }
          ]
        end
      end

      def include_month_grouping?
        @report.column_config.dig('group_by', 'month').present?
      end

      def include_company_grouping?
        @report.column_config.dig('group_by', 'company').present?
      end
    end
  end
end 