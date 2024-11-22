Rails.application.config.x.ollama = {
  url: ENV.fetch('OLLAMA_URL', 'https://your-vps-domain.com:11434'),
  api_key: ENV.fetch('OLLAMA_API_KEY', nil)
}
