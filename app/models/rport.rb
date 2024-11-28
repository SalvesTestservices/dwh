class Report < ApplicationRecord
  belongs_to :user
  has_one_attached :file
  
  validates :filename, presence: true
  validates :format, presence: true
  validates :status, presence: true

  enum status: {
    pending: 'pending',
    completed: 'completed',
    failed: 'failed'
  }
end
