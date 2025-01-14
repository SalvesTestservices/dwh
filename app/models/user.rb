class User < ApplicationRecord
  devise :invitable, :database_authenticatable, :recoverable, :omniauthable, 
      omniauth_providers: [:microsoft_graph], invite_for: 2.weeks

  has_many :chat_histories, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def self.from_omniauth(auth)
    # First try to find by provider/uid
    user = where(provider: auth.provider, uid: auth.uid).first

    # If not found, try to find by email
    user ||= find_by(email: auth.info.email)
    
    if user
      # Update existing user's provider/uid if needed
      user.update(
        provider: auth.provider,
        uid: auth.uid
      ) unless user.provider && user.uid
      return user
    end
  end
end 
