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
        
        [records, {
          columns: generate_group_columns,
          rows: generate_group_rows(grouped_data),
          total_count: grouped_data.size,
          current_page: 1,
          items_per_page: grouped_data.size
        }]
      end

      private

      def group_records(records)
        case @report.anchor_type.to_sym
        when :hours
          records.group_by do |record|
            dim_user = Dwh::DimUser.find_by(id: record.user_id)
            dim_account = Dwh::DimAccount.find_by(id: record.account_id)
            dim_company = Dwh::DimCompany.find_by(id: record.company_id)
            month = record.activity_date.to_s.length == 7 ? record.activity_date[1..2].to_i : record.activity_date[2..3].to_i
            year = record.activity_date.to_s.length == 7 ? record.activity_date[3..6].to_i : record.activity_date[4..7].to_i

            [
              record.user_id,
              dim_user&.full_name,
              dim_account&.name,
              dim_company&.name,
              month,
              year
            ]
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

      def generate_group_rows(grouped_data)
        case @report.anchor_type.to_sym
        when :hours
          grouped_data.map do |(user_id, full_name, account_name, company_name, month, year), records|
            {
              full_name: full_name,
              label: account_name,
              unit: company_name,
              month: I18n.t("date.month_names", locale: :nl)[month]&.capitalize || month.to_s,
              year: year,
              uren_ouderschapsverlof: records.sum { |r| r.hours.to_f }
            }
          end
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

      def include_month_grouping?
        @report.column_config.dig('group_by', 'month').present?
      end

      def include_company_grouping?
        @report.column_config.dig('group_by', 'company').present?
      end
    end
  end
end 