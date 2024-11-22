class DatalabCommunicator
  def initialize(query, user)
    @query = query
    @user = user
    @client = OllamaClient.new(base_url: ENV.fetch('OLLAMA_URL', 'http://localhost:11434'))
  end

  def process
    # Generate new SQL
    sql = generate_sql
    result = execute_sql(sql)

    # Store successful query for future use
    store_successful_query(sql) if result.present?

    {
      data: result,
      sql: sql,
      source: 'generated'
    }
  end

  def visualize(chart_type)
    ChartGenerator.new(@query, chart_type).generate
  end

  private def store_successful_query(sql)
    ChatHistory.create!(
      user: @user,
      question: @query,
      sql_query: sql,
      answer: result
    )
  end

  def generate_sql
    response = @client.generate(
      model: "sqlcoder",
      prompt: generate_prompt,
      stream: false
    )
    
    response.dig("response")&.strip
  end

  def generate_prompt
    <<~PROMPT
      Given the following database schema:
      #{database_schema}

      Important context:
      - Table names are in English and use the format: dim_* for dimensions and fact_* for fact tables
      - Common translations:
        * customers/klanten -> dim_customers
        * products/producten -> dim_products
        * sales/verkopen -> fact_sales
        * orders/bestellingen -> fact_orders

      User question (in Dutch): #{@query}
      
      Return only the SQL query, no explanations.
    PROMPT
  end

  private def database_schema
    File.read(Rails.root.join('db', 'dwh_schema.rb'))
  end
end