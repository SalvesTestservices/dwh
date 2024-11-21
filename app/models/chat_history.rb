class ChatHistory < ApplicationRecord
  belongs_to :user
  
  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :for_user, ->(user) { where(user: user) }
  
  validates :query, presence: true
  validates :sql, presence: true
  validates :status, presence: true, 
            inclusion: { in: %w[completed failed timeout] }
  validates :source, presence: true,
            inclusion: { in: %w[generated cache] }

  before_validation :generate_embedding, on: :create

  scope :successful, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :with_charts, -> { where.not(chart_type: nil) }

  private

  def generate_embedding
    self.embedding = self.class.generate_embedding_vector(query)
  end

  def self.generate_embedding_vector(text)
    client = OllamaClient.new(
      base_url: ENV.fetch('OLLAMA_URL', 'http://localhost:11434')
    )

    client.embeddings(text: text)
  end
end
