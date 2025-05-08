class Professional < ApplicationRecord
  belongs_to :user, optional: true
  has_many :appointments
  has_many :evolutions, through: :appointments
  has_many :professional_specialties
  has_many :specialties, through: :professional_specialties

  validates :name, presence: true
  validates :available_days, presence: true

  after_initialize :set_defaults

  # Garante que available_hours seja sempre um hash com os dias da semana
  def available_hours
    super.presence || {}
  end

  def hours_for(day)
    available_hours[day.to_s] || []
  end

  def add_hour_for(day, interval)
    h = available_hours
    h[day.to_s] ||= []
    h[day.to_s] << interval
    self.available_hours = h
  end

  private

  def set_defaults
    self.available_hours ||= {}
  end
end
