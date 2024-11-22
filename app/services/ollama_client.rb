class OllamaClient
  include HTTParty

  def initialize(base_url:)
    @base_url = base_url
    @headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['OLLAMA_API_KEY']}"
    }
  end

  def generate(model:, prompt:, stream: false)
    response = self.class.post(
      "#{@base_url}/api/generate",
      body: {
        model: model,
        prompt: prompt,
        stream: stream
      }.to_json,
      headers: @headers,
      verify: true,
      timeout: 120,  # 2 minutes total timeout
      read_timeout: 60,  # 1 minute read timeout
      open_timeout: 10   # 10 seconds connection timeout
    )

    unless response.success?
      raise "Ollama API error: #{response.code} - #{response.body}"
    end

    JSON.parse(response.body)
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    raise "Ollama API timeout: #{e.message}"
  rescue JSON::ParserError => e
    raise "Invalid JSON response: #{e.message}"
  rescue StandardError => e
    raise "Ollama API error: #{e.message}"
  end

  def embeddings(text:)
    response = self.class.post(
      "#{@base_url}/api/embeddings",
      body: {
        model: "llama2",  # or your preferred embedding model
        prompt: text
      }.to_json,
      headers: @headers,
      verify: true
    )

    JSON.parse(response.body).dig("embedding")
  end

  def pull_model(model_name)
    response = self.class.post(
      "#{@base_url}/api/pull",
      body: {
        name: model_name
      }.to_json,
      headers: @headers,
      verify: true
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

  def create_model(name:, base_model:, training_data:, chunk_size: 1000)
    self.class.post(
      "#{@base_url}/api/generate",
      body: {
        model: base_model,
        name: name,
        training_data: training_data,
        chunk_size: chunk_size
      }.to_json,
      headers: @headers,
      timeout: @timeout,
      read_timeout: @timeout,
      stream_body: true
    ) do |fragment|
      yield fragment if block_given?
    end
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Rails.logger.error "Timeout error: #{e.message}"
    raise OllamaTimeoutError, "Request timed out after #{@timeout} seconds"
  rescue StandardError => e
    Rails.logger.error "Ollama API error: #{e.message}"
    raise OllamaApiError, e.message
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