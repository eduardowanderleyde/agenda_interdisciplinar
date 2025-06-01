class Appointment < ApplicationRecord
  belongs_to :patient
  belongs_to :professional
  belongs_to :room
  belongs_to :specialty
  has_many :evolutions

  validate :no_time_conflict
  validate :room_available
  validate :patient_available

  private

  def no_time_conflict
    return unless professional && start_time && duration

    conflict_service = ConflictDetectionService.new
    if conflict_service.conflict_for_professional?(professional, start_time, start_time + duration.minutes)
      errors.add(:base, 'Conflito de horário para este profissional.')
    end
  end

  def room_available
    return unless room && start_time && duration

    conflict_service = ConflictDetectionService.new
    if conflict_service.conflict_for_room?(room, start_time, start_time + duration.minutes)
      errors.add(:base, 'Sala já está ocupada neste horário.')
    end
  end

  def patient_available
    return unless patient && start_time && duration

    conflict_service = ConflictDetectionService.new
    if conflict_service.conflict_for_patient?(patient, start_time, start_time + duration.minutes)
      errors.add(:base, 'O paciente já possui um agendamento neste horário.')
    end
  end
end
