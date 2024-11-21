class DatalabCommunicator
  def initialize(query, user)
    @query = query
    @user = user
    @client = OllamaClient.new(base_url: ENV.fetch('OLLAMA_URL', 'http://localhost:11434'))
  end

  def process
    # Check for similar previous queries first
    if similar_query = find_similar_query
      return {
        data: execute_sql(similar_query.sql),
        sql: similar_query.sql,
        source: 'cache'
      }
    end

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

  private

  def find_similar_query
    ChatHistory.find_similar_queries(@query, threshold: 0.8, limit: 1).first
  end

  def store_successful_query(sql)
    ChatHistory.create!(
      user: @user,
      query: @query,
      sql: sql,
      result: result,
      execution_time_ms: execution_time,
      status: 'completed'
    )
  end

  def generate_sql
    response = @client.generate(
      model: "sqlcoder",  # or your preferred SQL-focused model
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
end