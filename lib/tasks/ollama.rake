namespace :ollama do
  desc "Pull required Ollama models"
  task setup: :environment do
    client = OllamaClient.new(base_url: ENV.fetch('OLLAMA_URL', 'http://ollama:11434'))
    
    %w[sqlcoder].each do |model|
      start_time = Time.current
      puts "Pulling #{model}... (started at #{start_time.strftime('%H:%M:%S')})"
      begin
        client.pull_model(model)
        duration = Time.current - start_time
        puts "Successfully pulled #{model} (took #{duration.to_i} seconds)"
      rescue => e
        puts "Failed to pull #{model}: #{e.message}"
      end
    end
  end
end 