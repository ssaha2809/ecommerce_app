class User < ApplicationRecord
  enum :role, { customer: 0, admin: 1 }

  before_validation :ensure_api_token

  validates :email,     presence: true, uniqueness: { case_sensitive: false }
  validates :name,      presence: true
  validates :api_token, presence: true, uniqueness: true
  validates :role,      presence: true

  private

  def ensure_api_token
    self.api_token ||= SecureRandom.hex(24)
  end
end
