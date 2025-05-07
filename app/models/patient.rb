class Patient < ApplicationRecord
  has_many :appointments
  has_many :evolutions, through: :appointments
  has_many :patient_specialties
  has_many :specialties, through: :patient_specialties

  validates :name, presence: true
  validates :birthdate, presence: true
  validates :diagnosis, presence: true
end
