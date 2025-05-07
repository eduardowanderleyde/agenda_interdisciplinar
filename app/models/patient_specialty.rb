class PatientSpecialty < ApplicationRecord
  belongs_to :patient
  belongs_to :specialty

  validates :patient_id, uniqueness: { scope: :specialty_id }
end
