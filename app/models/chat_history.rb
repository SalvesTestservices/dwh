class ChatHistory < ApplicationRecord
  belongs_to :user

  validates :user_id, :sql_query, :question, presence: true

  scope :recent, -> { order(created_at: :desc).limit(10) }
  scope :for_user, ->(user) { where(user: user) }
end
