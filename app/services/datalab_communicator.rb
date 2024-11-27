class DatalabCommunicator
  def initialize(query, user, chat_session_id)
    @query = query
    @user = user
    @chat_session_id = chat_session_id
  end

  def process
    result = "OK"
    client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

    # Get SQL from Anthropic
    response = client.messages(
      parameters: {
        model: ENV.fetch("ANTHROPIC_MODEL"),
        messages: [
          { "role": "user", "content": generate_prompt }
        ],
        max_tokens: 1000
      }
    )

    # Extract SQL from response
    sql = response.dig("content", 0, "text")

    # Execute SQL and handle results
    result = execute_sql(sql)

    # Store successful query for future use
    store_successful_query(@user.id, @chat_session_id, @query, sql, result) unless result.include?("ERROR")

    # Return result
    puts "RESULT: #{result}"
    result
  rescue Anthropic::Error => e
    case e.status
    when 429
      result = "ERROR! Rate limit exceeded. Please try again later."
    when 500..599
      result = "ERROR! Service temporarily unavailable. Please try again later."
    else
      result = "ERROR! Error processing request: #{e.message}"
    end
    result
  end

  private def store_successful_query(user_id, chat_session_id, query, sql, result)
    puts "STORE SUCCESSFUL QUERY #{user_id} #{chat_session_id} #{query} #{sql} #{result}"
    ChatHistory.create!(
      user_id: user_id,
      session_id: chat_session_id,
      question: query,
      sql_query: sql,
      answer: result
    )
  end

  private def execute_sql(sql)
    return if sql.blank?

    # Sanitize and validate SQL to prevent dangerous operations
    result = "ERROR! Invalid SQL: Contains unsafe operations" if unsafe_sql?(sql)
    
    # Execute query with timeout protection
    DwhRecord.connection.execute(sql).to_a
  rescue ActiveRecord::StatementInvalid => e
    result = "ERROR! Invalid SQL query: #{e.message}"
  rescue PG::Error => e
    result = "ERROR! Database error: #{e.message}"
  rescue Timeout::Error => e
    result = "ERROR! Query timed out: #{sql}"
  end

  private def unsafe_sql?(sql)
    dangerous_keywords = [
      /\bDROP\b/i,
      /\bDELETE\b/i,
      /\bTRUNCATE\b/i,
      /\bINSERT\b/i,
      /\bUPDATE\b/i,
      /\bALTER\b/i,
      /\bCREATE\b/i
    ]

    dangerous_keywords.any? { |keyword| sql.match?(keyword) }
  end

  def generate_prompt
    <<~PROMPT
      Given the following database schema:
      #{database_schema}

      Previous successful queries:
      #{generate_chat_history}

      Dutch to English translations:
      #{load_translations}

      Query Guidelines:
      - When filtering on translated fields, use English values in WHERE clauses
      - Example: "medewerkers" -> WHERE role = 'employee'

      CRITICAL RULES:
      1. NEVER format or transform dates - they must be shown as raw integers
      2. NEVER use CONCAT, SUBSTRING, TO_CHAR, TO_DATE or any other date formatting
      3. Always use column::text for date columns to show the raw integer value

      Important context:
      - Table names are in English and use the format: dim_* for dimensions and fact_* for fact tables
      - When querying, always join with related dimension tables to show names instead of IDs:
        * account_id -> join with dim_accounts to show name
        * company_id -> join with dim_companies to show name
        * customer_id -> join with dim_customers to show name
        * user_id -> join with dim_users to show full_name
        * project_id -> join with dim_projects to show name
        * unbillable_id -> join with dim_unbillables to show name
        * projectuser_id -> join with fact_projectusers
      - Common translations:
        * bedrijf/bedrijven/label/labels -> dim_accounts
        * BV's/BV/Unit/Units -> dim_companies
        * klanten -> dim_customers
        * projecten -> dim_projects
        * unbillable/unbillables -> dim_unbillables
        * user/users/medewerker/medewerkers/consultant/consultants -> dim_users
        * activiteit/activiteiten/uren/tijd/tarief/tarieven -> fact_activities
        * projectinzet/projectinzetten/inzet/inzet medewerker/opdracht -> fact_projectusers
        * tarief/tarieven/kostrpijs.bcr/ucr/contract uren/gemiddeld tarief/uren/salaris -> fact_rates
      - Ignore these columns:
        * Table dim_accounts: id, original_id, created_at, updated_at
        * Table dim_companies: id, original_id, created_at, updated_at
        * Table dim_customers: id, original_id, created_at, updated_at
        * Table dim_projects: id, original_id, created_at, updated_at
        * Table dim_unbillables: id, original_id, created_at, updated_at
        * Table dim_users: id, original_id, created_at, updated_at, email, address, zipcode, unavailable_before, :employee_type
        * Table fact_activities: id, original_id, created_at, updated_at, refreshed, projectuser_id
        * Table fact_projectusers: id, original_id, created_at, updated_at
        * Table fact_rates: id, show_user, created_at, updated_at
      - Use the original column names (in English) in WHERE clauses and JOIN conditions
      - Translate the following columns to Dutch and return them in the same order as shown here, use these translation not for the query itself:
        * Table dim_accounts: name -> naam
        * Table dim_companies: name -> naam, name_short -> afkorting, account_id -> label
        * Table dim_customers: name -> naam, account_id -> label, status -> status
        * Table dim_projects: name -> naam, account_id -> label, status -> status, company_id -> unit, customer_id -> klant, calculation_type -> type, start_date -> startdatum, end_date -> einddatum, expected_end_date -> verwachte einddatum
        * Table dim_unbillables: name -> naam, name_short -> afkorting, account_id -> label
        * Table dim_users: full_name -> naam, account_id -> label, company_id -> unit, start_date -> startdatum, end_date -> datum uit dienst, role -> rol, contract -> contract, contract_hours -> uren, salary -> salaris, city -> woonplaats, country -> land
        * Table fact_activities: activity_date -> datum, account_id -> label, user_id -> medewerker, project_id -> project, unbillable_id -> unbillable code, customer_id -> klant, company_id -> unit, hours -> uren, rate -> tarief
        * Table fact_projectusers: project_id -> project, user_id -> medewerker, account_id -> label, start_date -> startdatum, end_date -> einddatum, expected_end_date -> verwachte einddatum
        * Table fact_rates: label -> label, company_id -> unit, user_id -> medewerker, rate_date -> datum, hours -> uren, avg_rate -> gemiddeld tarief, bcr -> BCR, ucr -> UCR, company_bcr -> BCR unit, company_ucr -> UCR unit, contract -> contract, contract_hours -> uren, salary -> salaris, role -> rol
      - Do the following actions when you are asked:
        * Omzet: calculate rate * hours
        * Productiviteit: calculate sum of hours
        * In dienst/Uit dienst use: (leave_date IS NULL OR leave_date >= [current_date_integer])

      Additional query guidelines:
      - For date handling:
        * Dates are stored and must be displayed as raw integers in YYYYMMDD format
        * Example: 20230101 for January 1st, 2023
        * Simply use: start_date::text, leave_date::text
        * For date comparisons, use: date_column >= EXTRACT(YEAR FROM CURRENT_DATE)::integer * 10000 + 
                                                   EXTRACT(MONTH FROM CURRENT_DATE)::integer * 100 + 
                                                   EXTRACT(DAY FROM CURRENT_DATE)::integer
      - When matching company/account names:
        * Use ILIKE for case-insensitive partial matches
        * Example: name ILIKE '%SALVES%' OR name_short ILIKE '%SALVES%'
      - For simple listing queries:
        * Return only relevant columns based on the question
        * Default sort should be by name/full_name
      - Active employee filter:
        * Use: (leave_date IS NULL OR leave_date >= [current_date_integer])

      User question (in Dutch): #{@query}

      Keep queries simple and focused on what's specifically asked. Only include columns that are relevant to the question.
      Return only the SQL query, no explanations.
      Always show meaningful columns in the result (names instead of IDs) and translate these to Dutch.
      Use the original English column names in the query logic, but alias them to Dutch names in the SELECT statement using AS.
    PROMPT
  end

  private def database_schema
    File.read(Rails.root.join('db', 'dwh_schema.rb'))
  end

  private def generate_chat_history
    # Get last 5 successful queries from the current chat session
    history = ChatHistory.where(session_id: @chat_session_id,).where.not(sql_query: nil).order(created_at: :desc).limit(5)

    return "" if history.empty?

    history.map do |chat|
      <<~HISTORY
        Question: #{chat.question}
        SQL: #{chat.sql_query}
        Result: #{chat.answer}
        ---
      HISTORY
    end.join("\n")
  end

  private def load_translations
    YAML.load_file(Rails.root.join('config', 'locales', 'data_attributes.nl.yml')).dig('nl', 'data_attributes').to_yaml
  end
end