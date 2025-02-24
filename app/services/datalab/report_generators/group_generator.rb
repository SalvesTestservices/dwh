module Datalab
  module ReportGenerators
    class GroupGenerator < BaseGenerator
      def generate
        records, _total_count = @anchor_service.fetch_data(
          @params[:filters],
          nil,
          nil
        )
        dump "RECORDS: #{records.count}"
        grouped_records = group_records(records, @params)
        #rows = generate_group_rows(grouped_data)
        #dump "ROWS: #{rows.inspect}"
        [records, {
          columns: generate_group_columns,
          rows: grouped_records,
          total_count: grouped_records.size,
          current_page: 1,
          items_per_page: grouped_records.size
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

      def group_records(records, params)
        grouped_records = []

        case @report.anchor_type.to_sym
        when :hours
          user_ids = []
          months = []

          records.each do |record|
            user_ids << record.user_id
            months << record.activity_date.to_s.length == 7 ? record.activity_date.to_s[1..2] : record.activity_date.to_s[2..3]
          end

          user_ids = user_ids.uniq
          months = months.uniq

          dump "USER IDS: #{user_ids.inspect}"
          dump "MONTHS: #{months.inspect}"

          user_ids.each do |user_id|
            months.each do |month|
              grouped_record = {}
              total_hours = 0.0
              matching_records = records.select do |record|
                record.user_id == user_id && 
                (record.activity_date.to_s.length == 7 ? 
                  record.activity_date.to_s[1..2] : 
                  record.activity_date.to_s[2..3]) == month
              end
              
              matching_records.each do |record|
                dim_account = Dwh::DimAccount.find_by(id: record.account_id)
                dim_company = Dwh::DimCompany.find_by(id: record.company_id)
                dim_user = Dwh::DimUser.find_by(id: record.user_id)
                year = record.activity_date.to_s.length == 7 ? record.activity_date.to_s[4..7] : record.activity_date.to_s[5..8]
                dump "USER #{dim_user.full_name} - #{dim_user.id}"
                dump "GROUPED_RECORD: #{grouped_record.inspect}"

                grouped_record[:user_id] ||= record.user_id
                grouped_record[:full_name] ||= dim_user&.full_name
                grouped_record[:label] ||= dim_account&.name
                grouped_record[:unit] ||= dim_company&.name
                grouped_record[:year] ||= year
                grouped_record[:month] ||= record.activity_date.to_s.length == 7 ? record.activity_date.to_s[1..2] : record.activity_date.to_s[2..3]

                total_hours += record.hours.to_f
              end

              grouped_record[:total_hours] ||= total_hours
              grouped_records << grouped_record
            end
          end

          dump "GROUPED RECORDS: #{grouped_records.inspect}"

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
        grouped_records
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