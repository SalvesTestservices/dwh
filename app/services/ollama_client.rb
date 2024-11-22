class OllamaClient
  include HTTParty

  def initialize(base_url:)
    @base_url = base_url
  end

  def generate(model:, prompt:, stream: false)
    response = self.class.post(
      "#{@base_url}/api/generate",
      body: {
        model: model,
        prompt: prompt,
        stream: stream
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    JSON.parse(response.body)
  end

  def embeddings(text:)
    response = self.class.post(
      "#{@base_url}/api/embeddings",
      body: {
        model: "llama2",  # or your preferred embedding model
        prompt: text
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    JSON.parse(response.body).dig("embedding")
  end

  def pull_model(model_name)
    response = self.class.post(
      "#{@base_url}/api/pull",
      body: {
        name: model_name
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    # Parse the response line by line
    response.body.split("\n").each do |line|
      next if line.empty?
      begin
        json = JSON.parse(line)
        if json['error']
          raise json['error']
        end
        # Log progress
        puts "Pull progress: #{json['status']}" if json['status']
      rescue JSON::ParserError => e
        # Skip invalid JSON chunks
        next
      end
    end

    true
  rescue HTTParty::Error => e
    raise "Failed to pull model: #{e.message}"
  end

  def create_model(name:, base_model:, training_data:)
    response = self.class.post(
      "#{@base_url}/api/create",
      body: {
        name: name,
        modelfile: generate_modelfile(base_model, training_data)
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    unless response.success?
      raise "Failed to create model: #{response.body}"
    end

    JSON.parse(response.body)
  end

  private

  def generate_modelfile(base_model, training_data)
    # Format training data according to Ollama's requirements
    formatted_data = training_data.map do |example|
      "# Example\nPrompt: #{example[:prompt]}\nCompletion: #{example[:completion]}"
    end.join("\n\n")

    <<~MODELFILE
      FROM #{base_model}
      
      # Training data
      #{formatted_data}
    MODELFILE
  end
end 