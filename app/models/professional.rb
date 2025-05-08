class Professional < ApplicationRecord
  belongs_to :user, optional: true
  has_many :appointments
  has_many :evolutions, through: :appointments
  has_many :professional_specialties
  has_many :specialties, through: :professional_specialties

  validates :name, presence: true
  validates :available_days, presence: true

  after_initialize :set_defaults

  private

  def set_defaults
    self.available_hours ||= []
  end
end
