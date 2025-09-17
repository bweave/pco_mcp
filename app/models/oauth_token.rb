class OauthToken < ActiveRecord::Base
  EXPIRES_IN = 3600 # 1 hour

  belongs_to :oauth_application
  belongs_to :account, optional: true

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  def expired?
    return false if expires_in.blank?

    Time.current > created_at + expires_in.seconds
  end

  def revoked?
    revoked_at.present?
  end

  def valid_for_requests?
    !expired? && !revoked?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def scopes_array
    scopes&.split(" ") || []
  end

  private

  def generate_token
    self.token = SecureRandom.hex(32) if token.blank?
  end
end
