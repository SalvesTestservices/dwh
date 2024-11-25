class DatalabCommunicator
  def initialize(query, user)
    @query = query
    @user = user
  end

  def process
    client = Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY'])

    # Get SQL from Anthropic
    response = client.messages(
      parameters: {
        model: ENV.fetch("ANTHROPIC_MODEL"),
        messages: [
          { "role": "user", "content": generate_prompt}
        ],
        max_tokens: 1000
      }
    )

    # Extract SQL from response
    sql = response.dig("content", 0, "text")
    
    # Execute SQL and handle results
    result = execute_sql(sql)

    # Store successful query for future use
    store_successful_query(@user.id, @query, sql, result) if result.present?

    {
      data: result,
      sql: sql
    }
  rescue StandardError => e
    Rails.logger.error("DatalabCommunicator Error: #{e.message}")
    {
      data: nil,
      sql: nil,
      error: "Failed to process query: #{e.message}"
    }
  end

  private def store_successful_query(user_id, query, sql, result)
    ChatHistory.create!(
      user_id: user_id,
      question: query,
      sql_query: sql,
      answer: result
    )
  end

  private def execute_sql(sql)
    return if sql.blank?

    # Sanitize and validate SQL to prevent dangerous operations
    raise "Invalid SQL: Contains unsafe operations" if unsafe_sql?(sql)
    
    # Execute query with timeout protection
    DwhRecord.connection.execute(sql).to_a
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error("SQL Execution Error: #{e.message}\nSQL: #{sql}")
    raise "Invalid SQL query: #{e.message}"
  rescue PG::Error => e
    Rails.logger.error("PostgreSQL Error: #{e.message}\nSQL: #{sql}")
    raise "Database error: #{e.message}"
  rescue Timeout::Error => e
    Rails.logger.error("SQL Query Timeout: #{sql}")
    raise "Query timed out"
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
        * customers/klanten -> dim_customers
        * products/producten -> dim_products
        * sales/verkopen -> fact_sales
        * orders/bestellingen -> fact_orders

      User question (in Dutch): #{@query}
      
      Return only the SQL query, no explanations.
      Always return meaningful columns in the result (names instead of IDs), except created_at and updated_at and translate these to Dutch and replace a underscore with a space.
      Always use meaningful column aliases when joining multiple tables that might have the same column names.
    PROMPT
  end

  private def database_schema
    File.read(Rails.root.join('db', 'dwh_schema.rb'))
  end

  private def translation_yml
    File.read(Rails.root.join('config', 'locales', 'dwh.nl.yml'))
  end
end