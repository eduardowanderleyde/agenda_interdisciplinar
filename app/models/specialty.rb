class Specialty < ApplicationRecord
  has_many :professional_specialties
  has_many :professionals, through: :professional_specialties

  has_many :patient_specialties
  has_many :patients, through: :patient_specialties

  validates :name, presence: true, uniqueness: true
  validates :default_duration, inclusion: { in: [30, 45, 60] }
end
