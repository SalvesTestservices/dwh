class User < ApplicationRecord
  devise :invitable, :database_authenticatable, :recoverable, :validatable,invite_for: 2.weeks

  has_many :chat_histories, dependent: :destroy

  validates :first_name, :last_name,:email, presence: true, uniqueness: true

  def full_name
    "#{first_name} #{last_name}"
  end
end 
