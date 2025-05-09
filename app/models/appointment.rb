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

    end_time = start_time + duration.minutes
    conflicts = Appointment.where(professional_id: professional_id)
                           .where.not(id: id)
                           .where("(start_time, (start_time + (duration * interval '1 minute'))) OVERLAPS (?, ?)", start_time, end_time)
    return unless conflicts.exists?

    errors.add(:base, 'Conflito de horário para este profissional.')
  end

  def room_available
    return unless room && start_time && duration

    end_time = start_time + duration.minutes
    conflicts = Appointment.where(room_id: room_id)
                           .where.not(id: id)
                           .where("(start_time, (start_time + (duration * interval '1 minute'))) OVERLAPS (?, ?)", start_time, end_time)
    return unless conflicts.exists?

    errors.add(:base, 'Sala já está ocupada neste horário.')
  end

  def patient_available
    return unless patient && start_time && duration

    end_time = start_time + duration.minutes
    conflicts = Appointment.where(patient_id: patient_id)
                           .where.not(id: id)
                           .where("(start_time, (start_time + (duration * interval '1 minute'))) OVERLAPS (?, ?)", start_time, end_time)
    return unless conflicts.exists?

    errors.add(:base, 'O paciente já possui um agendamento neste horário.')
  end
end
