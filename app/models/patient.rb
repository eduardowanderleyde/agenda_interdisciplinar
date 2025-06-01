class Patient < ApplicationRecord
  has_many :appointments, dependent: :destroy
  has_many :evolutions, through: :appointments
  has_many :patient_specialties, dependent: :destroy
  has_many :specialties, through: :patient_specialties

  # validates :name, presence: { message: "O nome não pode ficar em branco" }
  validates :birthdate, presence: { message: "A data de nascimento não pode ficar em branco" }
  validate :must_have_at_least_one_specialty
  validate :must_have_available_hours
  validate :name_presence_custom

  private

  def must_have_at_least_one_specialty
    return unless specialties.empty?
    errors.add(:base, 'É obrigatório selecionar pelo menos uma especialidade para o paciente.')
  end

  def must_have_available_hours
    ah = available_hours
    if ah.is_a?(String)
      begin
        ah = JSON.parse(ah) rescue {}
      rescue
        ah = {}
      end
    end
    ah = {} unless ah.is_a?(Hash)
    algum_dia = ah.values.any? { |v| v.present? && v.any?(&:present?) }
    unless algum_dia
      errors.add(:base, 'É obrigatório informar pelo menos um horário disponível em algum dia da semana.')
    end
  end

  def name_presence_custom
    if name.blank?
      errors.add(:base, 'O nome não pode ficar em branco')
    end
  end
end
