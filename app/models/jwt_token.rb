class JwtToken < ApplicationRecord
  belongs_to :user

  validates :jti, presence: true, uniqueness: true
  validates :exp, presence: true

  scope :valid, -> { where("exp > ?", Time.current) }
  scope :expired, -> { where("exp <= ?", Time.current) }

  def expired?
    exp <= Time.current
  end
end
