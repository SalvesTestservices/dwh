class OllamaClient
  def initialize(base_url:)
    @base_url = base_url
  end

  def generate(model:, prompt:, stream: false)
    response = HTTP.post(
      "#{@base_url}/api/generate",
      json: {
        model: model,
        prompt: prompt,
        stream: stream
      }
    )

    JSON.parse(response.body)
  end

  def embeddings(text:)
    response = HTTP.post(
      "#{@base_url}/api/embeddings",
      json: {
        model: "llama2",  # or your preferred embedding model
        prompt: text
      }
    )

    JSON.parse(response.body).dig("embedding")
  end
end 