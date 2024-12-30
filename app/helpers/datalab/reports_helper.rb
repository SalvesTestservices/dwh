module Datalab
  module ReportsHelper
    def sort_link(report, field, name)
      current_direction = params[:sort_direction] == 'asc' ? 'desc' : 'asc'
      active_class = params[:sort_by] == field.to_s ? 'text-blue-600' : ''
      
      link_to generate_datalab_report_path(report, sort_by: field, sort_direction: current_direction),
              class: "group inline-flex #{active_class}",
              data: { turbo_frame: 'report_data' } do
        concat name
        concat sort_indicator(field, current_direction)
      end
    end

    private

    def sort_indicator(field, direction)
      return '' unless params[:sort_by] == field.to_s

      icon_class = direction == 'asc' ? 'rotate-180' : ''
      content_tag :svg, 
                 content_tag(:path, '', fill_rule: 'evenodd', d: 'M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z'),
                 class: "ml-2 h-5 w-5 #{icon_class}",
                 viewBox: '0 0 20 20',
                 fill: 'currentColor'
    end

    def filter_options_for_attribute(attr)
      case attr
      when :account_id
        Dwh::DimAccount.order(:name).map { |account| [account.name, account.id] }
      when :company_id
        Dwh::DimCompany.order(:name).map { |company| [company.name, company.id] }
      when :role
        Dwh::DimUser.distinct.pluck(:role).sort.map { |role| [role, role] }
      when :contract
        Dwh::DimUser.distinct.pluck(:contract).sort.map { |contract| [contract, contract] }
      else
        []
      end
    end
  end
end
