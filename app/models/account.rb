class Account < ActiveRecord::Base
  has_many :oauth_grants, dependent: :destroy
  has_many :oauth_tokens, dependent: :destroy
  has_one :planning_center_token, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :planning_center_id, uniqueness: true, allow_nil: true

  def planning_center_authenticated?
    planning_center_token&.access_token.present?
  end

  def planning_center_token_valid?
    return false unless planning_center_authenticated?
    return true if planning_center_token.expires_at.nil?

    planning_center_token.expires_at > Time.current
  end
end
