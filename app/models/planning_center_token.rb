class PlanningCenterToken < ActiveRecord::Base
  belongs_to :account

  validates :access_token, presence: true

  # TODO: add home scope
  PLANNING_CENTER_SCOPES = %w[
    people
    services
    calendar
    check_ins
    giving
    groups
    publishing
  ].freeze

  def expired?
    return false if expires_at.blank?

    expires_at <= Time.current
  end

  def needs_refresh?
    expired? && refresh_token.present?
  end

  def scopes_array
    scopes&.split(" ") || []
  end

  def has_scope?(scope)
    scopes_array.include?(scope.to_s)
  end

  def all_scopes?
    PLANNING_CENTER_SCOPES.all? { |scope| has_scope?(scope) }
  end
end
