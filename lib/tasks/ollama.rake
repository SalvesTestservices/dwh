namespace :ollama do
  desc "Pull required Ollama models"
  task setup: :environment do
    client = OllamaClient.new(base_url: ENV.fetch('OLLAMA_URL', 'http://localhost:11434'))
    
    %w[sqlcoder llama2].each do |model|
      puts "Pulling #{model}..."
      system("ollama pull #{model}")
    end
  end
end 