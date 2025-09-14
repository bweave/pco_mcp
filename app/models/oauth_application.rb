class OauthApplication < ActiveRecord::Base
  has_many :oauth_grants, dependent: :destroy
  has_many :oauth_tokens, dependent: :destroy

  validates :name, presence: true
  validates :uid, presence: true, uniqueness: true
  validates :secret, presence: true
  validates :redirect_uri, presence: true

  before_validation :generate_uid, :generate_secret, on: :create

  def supports_pkce?
    !confidential
  end

  private

  def generate_uid
    self.uid = SecureRandom.uuid if uid.blank?
  end

  def generate_secret
    self.secret = SecureRandom.hex(32) if secret.blank?
  end
end
