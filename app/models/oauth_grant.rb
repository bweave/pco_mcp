class OauthGrant < ActiveRecord::Base
  belongs_to :oauth_application
  belongs_to :account

  validates :code, presence: true, uniqueness: true
  validates :expires_in, presence: true
  validates :redirect_uri, presence: true

  before_validation :generate_code, on: :create

  def expired?
    Time.current > created_at + expires_in.seconds
  end

  def revoked?
    revoked_at.present?
  end

  def valid_for_exchange?
    !expired? && !revoked?
  end

  def supports_pkce?
    code_challenge.present? && code_challenge_method.present?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def generate_code
    self.code = SecureRandom.hex(32) if code.blank?
  end
end
