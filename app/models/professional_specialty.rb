class ProfessionalSpecialty < ApplicationRecord
  belongs_to :professional
  belongs_to :specialty

  validates :professional_id, uniqueness: { scope: :specialty_id }
end
