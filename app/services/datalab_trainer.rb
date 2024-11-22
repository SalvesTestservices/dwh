class DatalabTrainer
  def train
    # Generate training data
    training_data = generate_training_data
    
    # Train the model using Ollama's API
    client = OllamaClient.new(base_url: ENV.fetch('OLLAMA_URL', 'http://ollama:11434'))

    # Create a fine-tuned model using Ollama's API
    response = client.create_model(
      name: "sqlcoder-dwh",
      base_model: "sqlcoder",
      training_data: training_data
    )

    Rails.logger.info "Model training started: #{response}"
  end

  private

  def generate_training_data
    data = []
    
    # Add schema information
    data << generate_schema_examples
    
    # Add sample queries and results
    data << generate_query_examples
    
    data
  end

  def generate_schema_examples
    examples = []
    
    # Query only DWH database schema
    DwhRecord.connection.tables
      .select { |t| t.start_with?('dim_', 'fact_') }
      .each do |table|
        columns = DwhRecord.connection.columns(table)
        examples << {
          prompt: "What columns are in the #{table} table?",
          completion: columns.map(&:name).join(", ")
        }
      end
    
    examples
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