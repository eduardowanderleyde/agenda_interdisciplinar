class Patient < ApplicationRecord
  has_many :appointments
  has_many :evolutions, through: :appointments
  has_many :patient_specialties, dependent: :destroy
  has_many :specialties, through: :patient_specialties

  validates :name, presence: true
  validates :birthdate, presence: true
  validates :diagnosis, presence: true
  validate :must_have_at_least_one_specialty

  private

  def must_have_at_least_one_specialty
    return unless specialties.empty?

    errors.add(:specialties, 'é obrigatório selecionar pelo menos uma especialidade para o paciente.')
  end
end
