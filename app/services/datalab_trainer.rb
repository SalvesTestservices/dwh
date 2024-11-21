class DatalabTrainer
  def train
    # Generate training data
    training_data = generate_training_data
    
    # Train the model using Ollama's API
    client = OpenAI::Client.new(
      access_token: ENV['OPENAI_API_KEY'],
      uri_base: "http://localhost:11434/v1"
    )

    client.fine_tunes.create(
      model: "sqlcoder",
      training_data: training_data
    )
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
    # Generate examples based on your schema
    ActiveRecord::Base.connection.tables
      .select { |t| t.start_with?('dim_', 'fact_') }
      .map do |table|
        columns = ActiveRecord::Base.connection.columns(table)
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