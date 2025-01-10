class Api::V2::DwhController < Api::V2::BaseController
  before_action :authenticate_user

  ### VIEW TABLES ###

  def view_fact_rates    
    sql = get_sql("view_fact_rates")
    result = execute_query(sql)
    json = result.to_json

    render json: json, status: :created  
  end

  def view_contracts
    sql = get_sql("view_contracts")
    result = execute_query(sql)
    json = result.to_json

    render json: json, status: :created  
  end

  def view_fact_activities
    sql = get_sql("view_fact_activities")
    result = execute_query(sql)
    json = result.to_json

    render json: json, status: :created  
  end

  def view_fact_targets_individual
    sql = get_sql("view_fact_targets_individual")
    result = execute_query(sql)
    json = result.to_json

    render json: json, status: :created  
  end

  def view_dim_customers
    sql = get_sql("view_dim_customers")
    result = execute_query(sql)
    json = result.to_json

    render json: json, status: :created  
  end

  def view_dim_projects
    sql = get_sql("view_dim_projects")
    result = execute_query(sql)
    json = result.to_json
    
    render json: json, status: :created  
  end

  def view_dim_companies
    sql = get_sql("view_dim_companies")
    result = execute_query(sql)
    json = result.to_json

    render json: json, status: :created  
  end

  def view_dim_users
    sql = get_sql("view_dim_users")
    result = execute_query(sql)
    json = result.to_json

    render json: json, status: :created  
  end

  ### FACT TABLES ###

  def fact_targets
    fact_targets = Dwh::FactTarget.all
    json = fact_targets.as_json
    render json: json, status: :created  
  end

  def fact_invoices
    fact_invoices = Dwh::FactInvoice.all
    json = fact_invoices.as_json
    render json: json, status: :created  
  end

  def fact_rates
    fact_rates = Dwh::FactRate.all
    json = fact_rates.as_json
    render json: json, status: :created  
  end

  def fact_activities
    fact_activities = Dwh::FactActivity.all
    json = fact_activities.as_json
    render json: json, status: :created  
  end

  def fact_projectusers
    fact_projectusers = Dwh::FactProjectuser.all
    json = fact_projectusers.as_json
    render json: json, status: :created  
  end

  ### DIM TABLES ###

  def dim_accounts
    dim_accounts = Dwh::DimAccount.all
    json = dim_accounts.as_json
    render json: json, status: :created  
  end

  def dim_companies
    dim_companies = Dwh::DimCompany.all
    json = dim_companies.as_json
    render json: json, status: :created  
  end

  def dim_users
    dim_users = Dwh::DimUser.all
    json = dim_users.as_json
    render json: json, status: :created  
  end

  def dim_customers
    dim_customers = Dwh::DimCustomer.all
    json = dim_customers.as_json
    render json: json, status: :created  
  end

  def dim_unbillables
    dim_unbillables = Dwh::DimUnbillable.all
    json = dim_unbillables.as_json
    render json: json, status: :created  
  end

  def dim_projects
    dim_projects = Dwh::DimProject.all
    json = dim_projects.as_json
    render json: json, status: :created  
  end

  def dim_dates
    dim_dates = Dwh::DimDate.all
    json = dim_dates.as_json
    render json: json, status: :created  
  end

  def dim_roles
    dim_roles = Dwh::DimRole.all
    json = dim_roles.as_json
    render json: json, status: :created  
  end

  private def get_sql(view)
    case view
    when "view_dim_customers"
      sql = "-- Append the account name to the customer name to be able to distinguish between the same customers of different accounts
        SELECT
          dc.*,
          concat(dc.name, ' (', da.name, ')') AS name_account
        FROM
          dim_customers dc
        LEFT JOIN 
          dim_accounts da 
          ON dc.account_id = da.id;"
    when "view_dim_projects"
      sql = "-- Add yearmonths and Dutch version of calculation types for use in dashboarding
        SELECT
          dp.*
          , CASE 
            WHEN dp. calculation_type = 'hour_based' THEN 'Consultancy'
            WHEN dp. calculation_type = 'fixed_price' THEN 'Fixed price'
            WHEN dp. calculation_type = 'service' THEN 'Licentie'
            WHEN dp. calculation_type = 'training' THEN 'Training'		
            else dp. calculation_type -- copy any remaining entries
          END AS calculation_type_nl,
          sd.yearmonth AS start_date_yearmonth,
          ed.yearmonth AS end_date_yearmonth
        FROM
          dim_projects dp
        LEFT JOIN 
          dim_dates sd
          ON dp.start_date = sd.id
        LEFT JOIN 
          dim_dates ed
          ON dp.end_date = ed.id;"
    when "view_dim_users"
      sql = "SELECT 
          du.*,
          COALESCE(ud.original_date, av.available_per, make_date(sd.year, sd.month, sd.day)) AS available_per,				-- Take the available per date based on (in order of priority) unavailable_before, dim_projectusers, or start_date if user has not had a project
          CASE 
            WHEN CURRENT_DATE >= make_date(ld.year, ld.month, ld.day) THEN '5. niet beschikbaar'							-- Not available (employment ended)
            WHEN 
              COALESCE(av.available_per, make_date(sd.year, sd.month, sd.day)) <= CURRENT_DATE OR 
              COALESCE(av.available_per, make_date(sd.year, sd.month, sd.day)) IS NULL 
              THEN '1. per direct'																						-- Direct availability when available_per equals or is earlier than today, or when available_per is blank (happens when user does not appear in dim_projectusers yet)
            WHEN 
              COALESCE(av.available_per, make_date(sd.year, sd.month, sd.day)) > CURRENT_DATE AND 
              COALESCE(av.available_per, make_date(sd.year, sd.month, sd.day)) <= CURRENT_DATE + 30 
              THEN '2. komende 30d'																						-- Becomes available in the next 30 days
            WHEN 
              COALESCE(av.available_per, make_date(sd.year, sd.month, sd.day)) > CURRENT_DATE + 30 AND 
              COALESCE(av.available_per, make_date(sd.year, sd.month, sd.day)) <= CURRENT_DATE + 60 
              THEN '3. komende 31-60d'																					-- Becomes available in the next 31-60 days
            WHEN 
              COALESCE(av.available_per, make_date(sd.year, sd.month, sd.day)) > CURRENT_DATE + 60 
              THEN '4. vanaf 61d+'																						-- Becomes available from the next 61+ days
          END AS availability_bin,
          ch.contract_hours_current
          
        FROM 
          dim_users du
        LEFT JOIN 
          view_users_available_per av
          ON du.id = av.user_id
        LEFT JOIN 
          view_users_contract_hours ch
          ON du.id = ch.user_id
        LEFT JOIN 
          dim_dates sd
          ON du.start_date = sd.id	
        LEFT JOIN 
          dim_dates ld
          ON du.leave_date = ld.id
        LEFT JOIN
          dim_dates ud
          ON du.unavailable_before = ud.id;"
    when "view_fact_targets_individual"
      sql = "-- Add individual targets for gross margin and billable hours to fact_rates
        SELECT
            fr.id,
            fr.account_id,
            fr.company_id,
            fr.user_id,
            fr.bcr,
            fr.contract_hours,
            GREATEST(fr.created_at, ft.created_at) AS created_at,
            GREATEST(fr.updated_at, ft.updated_at) AS updated_at,
            fr.role,
            ft.role_group,
            ft.bruto_margin,
            ft.workable_hours AS workable_hours_fte_equivalent,
            ft.billable_hours AS billable_hours_fte_equivalent,
            ft.employee_attrition,
            ft.employee_absence,
            ft.quarter,
            ft.target_date
        FROM
            fact_rates fr
        LEFT JOIN
            dim_roles dr
            ON fr.role = dr.role
        LEFT JOIN 
            fact_targets ft 
            ON fr.company_id = ft.company_id
            AND dr.category = ft.role_group
            AND fr.rate_date = ft.target_date;"
    when "view_dim_companies"
      sql = "SELECT
        *
        , CASE
          
          -- Cerios
          WHEN name = 'Cerios BV' THEN 'Cerios B.V.'
          
          -- Salves
          WHEN name = 'Salves Beheer BV' THEN 'Salves - Beheer'
          WHEN name = 'Salves Testservices Zorg B.V.' THEN 'Salves - Zorg'
          WHEN name = 'Salves Traineeship BV' THEN 'Salves - Traineeship'
          WHEN name = 'Salves West B.V.' THEN 'Salves - West'
          WHEN name = 'Salves Business Productivity B.V.' THEN 'Salves - Business Productivity'
          WHEN name = 'Salves HR & Payroll Services B.V.' THEN 'Salves - HR & Payroll'
          WHEN name = 'Salves Testservices Midden B.V.' THEN 'Salves - Midden'
          WHEN name = 'Salves Testservices West B.V.' THEN 'Salves - RWS'
          WHEN name = 'Salves Testservices Zuid B.V.' THEN 'Salves - Zuid'
          WHEN name = 'Salves Development B.V.' THEN 'Salves - Development'
          WHEN name = 'Salves Testservices Noord B.V.' THEN 'Salves - Noord'
          
          -- QDAT
          WHEN name = 'De Agile Testers Belgie' THEN 'QDAT - Agile Testers BE'
          WHEN name = 'De Agile Testers' THEN 'QDAT - Agile Testers NL'
          WHEN name = 'Quality Accelerators' THEN 'QDAT - Quality Accelerators'
    
          -- Valori
          WHEN name = 'Unit Business IT Improvement' THEN 'Valori - BIT'
          WHEN name = 'Unit Testautomation Engineering (TAE)' THEN 'Valori - TAE'
          WHEN name = 'Unit Testautomation Specialists (TAS)' THEN 'Valori - TAS'
          WHEN name = 'Unit Low Code Testing' THEN 'Valori - LCT'
          WHEN name = 'Unit Agile Testing 2' THEN 'Valori - AT2'
          WHEN name = 'Unit Agile Testing 1' THEN 'Valori - AT1'
          WHEN name = 'Unit Testautomation Architects (TAA)' THEN 'Valori - TAA'
          WHEN name = 'Unit QA& Test Advisory' THEN 'Valori - QTA'
          WHEN name = 'Unit Valori' THEN 'Valori - Unit Valori'
    
          -- Test Crew IT
          WHEN name = 'Test Crew IT B.V.' THEN 'Test Crew IT'			
          
          -- Copy any remaining entries
          ELSE name		
          
        END AS name_shorter
      FROM
        dim_companies;"
    when "view_fact_activities"
      sql = "-- Selecting columns from fact_activities table along with additional computed columns
      SELECT 
        fa.*,
          dd.year * 100 + dd.month AS year_month,
          fr.bcr as cost_per_billable_hour,
          CASE WHEN vdp.calculation_type = 'hour_based' THEN 1 ELSE 0 END AS is_hour_based,                            									-- flag hour based work (legacy)
          vdp.calculation_type_nl,                                                                                                                        -- calculation_type (new, for use in dashboard slicer for now)
          ROUND(fr.avg_contract_hours * ww.num_work_weeks / COUNT(1) OVER (PARTITION BY fa.user_id, dd.yearmonth), 5) AS contract_hours_part,             -- fraction of contract_hours for each row
          CASE WHEN fa.unbillable_id IS NULL THEN fa.hours ELSE 0 END AS hours_billable,                                                                  -- no unbillable code: billable
          CASE WHEN du.name_short IN ('Z', 'RI') AND long_sick.user_id IS NOT NULL THEN fa.hours ELSE 0 END AS hours_sick_long,                           -- Z: ziekte, RI: reintegratie
          CASE WHEN du.name_short IN ('Z', 'RI') AND long_sick.user_id IS NULL THEN fa.hours ELSE 0 END AS hours_sick_short,                              -- Z: ziekte, RI: reintegratie
          CASE WHEN du.name_short = 'I' THEN fa.hours ELSE 0 END AS hours_no_project,                                                                      -- I: geen opdracht (leegloop)
          fr.role
      FROM 
          fact_activities fa
      LEFT JOIN 
          dim_unbillables du ON fa.unbillable_id = du.id
      INNER JOIN 
          dim_dates AS dd ON fa.activity_date = dd.id
      LEFT JOIN 
          view_average_contract_hours_per_month AS fr 
          ON fr.user_id = fa.user_id 
          AND dd.year * 100 + dd.month = fr.yearmonth
      LEFT JOIN 
          view_work_weeks_per_month AS ww 
          ON dd.year * 100 + dd.month = ww.yearmonth
      LEFT JOIN 
          view_long_sick AS long_sick 
          ON dd.year = long_sick.year 
          AND dd.week_nr = long_sick.week_nr 
          AND fa.user_id = long_sick.user_id
      LEFT JOIN
        view_dim_projects vdp
          ON fa.project_id = vdp.id;"
    when "view_contracts"
      sql = "SELECT
          vpc.*,
          dd.id AS yearmonth_key, -- add the date of the current year/month combination as a foreign key to dim_dates
          
          -- If the start date of a contract falls in the current month and the contract_type is 'new', then the contract has started
          CASE
              WHEN dd.yearmonth = sd.yearmonth AND vpc.contract_type = 'new' THEN 1
              ELSE 0
          END AS contract_started,
          
          -- If the start date falls in the current month, the contract_type is 'extension', and the contract doesn't end in the current month, then the contract was extended  
          CASE
              WHEN dd.yearmonth = sd.yearmonth AND vpc.contract_type = 'extension' 
                  AND (
                      sd.yearmonth <> ed.yearmonth 
                      OR ed.yearmonth IS NULL
                      )
                  THEN 1
              ELSE 0
          END AS contract_extended,
          
          -- If the start date of the contract is earlier than the current month, the end date is later than the current month or empty, and the contract_type is 'new', then the contract is running
          -- If the contract date falls within the current month, the contract_type is extension, and the contract doesn't end in the current month, then correct the number of running contracts by -1
          -- (Without this correction, a new contract would still be running in the same month as the extension happened, causing this contract to be counted twice)
          CASE
              WHEN dd.yearmonth > sd.yearmonth
                  AND (
                      dd.yearmonth < ed.yearmonth
                      OR ed.yearmonth IS NULL
                  )
                  AND vpc.contract_type = 'new' THEN 1
              WHEN dd.yearmonth = sd.yearmonth AND vpc.contract_type = 'extension'
                  AND (
                      sd.yearmonth <> ed.yearmonth
                      OR ed.yearmonth IS NULL
                      )
                  THEN -1
              ELSE 0
          END AS contract_running,
          
          -- If the end date falls in the current month, the start date is earlier than the current month, and the contract_type is 'new', then the contract has ended
          -- This means that contracts that start and end in the same month will only count as contract_started or contract_extended, and not as contract_ended
          CASE
              WHEN dd.yearmonth = ed.yearmonth
                  AND dd.yearmonth > sd.yearmonth 
                  AND vpc.contract_type = 'new' THEN 1
              ELSE 0
          END AS contract_ended
          
      FROM
          view_projectusers_contract_types AS vpc -- Deduplicated contracts based on fact_projectusers
      
      -- Left join with dim_dates to get start date
      LEFT JOIN 
          dim_dates sd
          ON vpc.start_date = sd.id
      
      -- Left join with dim_dates to get end date
      LEFT JOIN 
          dim_dates ed
          ON vpc.expected_end_date = ed.id
      
      LEFT JOIN
          dim_dates dd 
          ON sd.yearmonth <= dd.yearmonth
          AND (
              ed.yearmonth >= dd.yearmonth
              OR ed.yearmonth IS NULL
          ) -- also return contracts with no end date
      
      WHERE
          dd.day = 1 -- at the level of individual months"
    when "view_fact_rates"
      sql = "-- Main query to select data with additional information
        SELECT 
            rp.*,
            CASE WHEN uwp.user_id IS NOT NULL THEN 1 ELSE 0 END AS has_project,
            COALESCE(LAG(rp.contract_hours, 1) OVER (PARTITION BY rp.user_id ORDER BY rd.yearmonth), 0) AS contract_hours_prev_month,
            rd.yearmonth
        FROM
            view_fact_rates_prognosis rp 
        JOIN
            dim_dates rd 
            ON rp.rate_date = rd.id    
        LEFT JOIN
            view_users_with_projects uwp 
            ON rp.user_id = uwp.user_id 
            AND rd.yearmonth = uwp.yearmonth
        LEFT JOIN 
            dim_users du
            ON rp.user_id = du.id
        LEFT JOIN 
            dim_dates ds 
            ON du.start_date = ds.id 
        LEFT JOIN 
            dim_dates dl 
            ON du.leave_date = dl.id;"
    end
  end
end
