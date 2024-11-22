class DatalabTrainer
  def train
    # Break down training data into smaller chunks
    training_data = generate_training_data
    chunk_size = 1000  # Adjust based on your needs
    
    training_data.each_slice(chunk_size) do |chunk|
      client = OllamaClient.new(
        base_url: ENV.fetch('OLLAMA_URL', 'http://ollama:11434'),
        timeout: 300  # 5 minutes
      )

      response = client.create_model(
        name: "sqlcoder-dwh",
        base_model: "sqlcoder",
        training_data: chunk,
        chunk_size: chunk_size
      )

      Rails.logger.info "Model training chunk processed: #{response}"
    end
  end

  private

  def generate_training_data
    data = []
    
    # Add schema information in smaller batches
    DwhRecord.connection.tables
      .select { |t| t.start_with?('dim_', 'fact_') }
      .each_slice(10) do |tables|
        data.concat(generate_schema_examples_for_tables(tables))
      end
    
    # Add sample queries in smaller batches
    data.concat(generate_query_examples)
    
    data
  end

  def generate_schema_examples_for_tables(tables)
    tables.flat_map do |table|
      columns = DwhRecord.connection.columns(table)
      {
        prompt: "What columns are in the #{table} table?",
        completion: columns.map(&:name).join(", ")
      }
    end
  end

  def generate_query_examples
    [
      {
        prompt: "Show me the top 10 customers by revenue",
        completion: %{
          SELECT 
            c.name as customer_name,
            SUM(fa.hours * fa.rate) as revenue
          FROM fact_activities fa
          JOIN dim_customers c ON c.id = fa.customer_id
          GROUP BY c.name
          ORDER BY revenue DESC
          LIMIT 10
        }
      }
      # Add more example queries here
    ]
  end
end 