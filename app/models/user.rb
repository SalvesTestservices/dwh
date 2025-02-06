class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :omniauthable, :timeoutable,
      omniauth_providers: [:microsoft_graph]

  validates :email, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  def full_name
    "#{first_name} #{last_name}"
  end

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  def viewer?
    role == "viewer"
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
