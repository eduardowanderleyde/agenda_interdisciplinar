# frozen_string_literal: true

# Serviço responsável por detectar conflitos de horário
#
# Este serviço encapsula toda a lógica relacionada à detecção de conflitos
# de horário, incluindo:
# - Conflitos de horário para profissionais
# - Conflitos de horário para pacientes
# - Conflitos de horário para salas
# - Verificação de conflitos em lote
# - Verificação de conflitos em agendas
#
# @example Verificar conflito para profissional
#   service = ConflictDetectionService.new
#   has_conflict = service.conflict_for_professional?(professional, start_time, end_time)
#
# @example Verificar conflito para paciente
#   service = ConflictDetectionService.new
#   has_conflict = service.conflict_for_patient?(patient, start_time, end_time)
#
# @example Verificar conflito para sala
#   service = ConflictDetectionService.new
#   has_conflict = service.conflict_for_room?(room, start_time, end_time)
#
# @example Verificar conflitos em lote
#   service = ConflictDetectionService.new
#   conflicts = service.batch_conflicts(appointments)
#
# @example Verificar conflitos em agenda
#   service = ConflictDetectionService.new
#   conflicts = service.check_agenda_conflicts(agenda)
class ConflictDetectionService
  # Verifica se há conflito de horário para um profissional
  #
  # @param professional [Professional] profissional para verificar conflito
  # @param start_time [DateTime] início do horário
  # @param end_time [DateTime] fim do horário
  # @return [Boolean] true se houver conflito, false caso contrário
  def conflict_for_professional?(professional, start_time, end_time)
    return false unless professional && start_time && end_time

    Rails.cache.fetch("professional_conflict_#{professional.id}_#{start_time}_#{end_time}", expires_in: 1.hour) do
      Appointment.where(professional: professional)
                .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?",
                       end_time, start_time)
                .exists?
    end
  end

  # Verifica se há conflito de horário para um paciente
  #
  # @param patient [Patient] paciente para verificar conflito
  # @param start_time [DateTime] início do horário
  # @param end_time [DateTime] fim do horário
  # @return [Boolean] true se houver conflito, false caso contrário
  def conflict_for_patient?(patient, start_time, end_time)
    return false unless patient && start_time && end_time

    Rails.cache.fetch("patient_conflict_#{patient.id}_#{start_time}_#{end_time}", expires_in: 1.hour) do
      Appointment.where(patient: patient)
                .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?",
                       end_time, start_time)
                .exists?
    end
  end

  # Verifica se há conflito de horário para uma sala
  #
  # @param room [Room] sala para verificar conflito
  # @param start_time [DateTime] início do horário
  # @param end_time [DateTime] fim do horário
  # @return [Boolean] true se houver conflito, false caso contrário
  def conflict_for_room?(room, start_time, end_time)
    return false unless room && start_time && end_time

    Rails.cache.fetch("room_conflict_#{room.id}_#{start_time}_#{end_time}", expires_in: 1.hour) do
      Appointment.where(room: room)
                .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?",
                       end_time, start_time)
                .exists?
    end
  end

  # Verifica se há qualquer tipo de conflito para um agendamento
  #
  # @param appointment [Appointment] agendamento para verificar conflitos
  # @return [Boolean] true se houver qualquer conflito, false caso contrário
  def any_conflict?(appointment)
    return false unless appointment

    start_time = appointment.start_time
    end_time = start_time + appointment.duration.minutes

    Rails.cache.fetch("any_conflict_#{appointment.id}_#{start_time}_#{end_time}", expires_in: 1.hour) do
      conflict_for_professional?(appointment.professional, start_time, end_time) ||
        conflict_for_patient?(appointment.patient, start_time, end_time) ||
        conflict_for_room?(appointment.room, start_time, end_time)
    end
  end

  # Verifica conflitos em lote para múltiplos agendamentos
  #
  # @param appointments [Array<Appointment>] array de agendamentos para verificar
  # @return [Array<Hash>] array com os detalhes dos conflitos encontrados
  def batch_conflicts(appointments)
    return [] unless appointments.any?

    Rails.cache.fetch("batch_conflicts_#{appointments.map(&:id).join('_')}", expires_in: 1.hour) do
      conflicts = []
      appointments.each do |appointment|
        if any_conflict?(appointment)
          conflicts << {
            patient_id: appointment.patient_id,
            professional_id: appointment.professional_id,
            room_id: appointment.room_id,
            start_time: appointment.start_time,
            specialty_id: appointment.specialty_id,
            motivo: "Conflito de sala, profissional ou paciente no horário"
          }
        end
      end
      conflicts
    end
  end

  # Verifica conflitos em uma agenda
  #
  # @param agenda [Hash] hash com os slots da agenda
  # @return [Array<Hash>] array com os detalhes dos conflitos encontrados
  def check_agenda_conflicts(agenda)
    return [] unless agenda && agenda['slots']

    Rails.cache.fetch("agenda_conflicts_#{agenda['slots'].map { |s| s.values.join('_') }.join('_')}", expires_in: 1.hour) do
      conflicts = []
      agenda['slots'].each do |slot|
        professional = Professional.find_by(name: slot['profissional'])
        room = Room.find_by(name: slot['sala'])
        start_time = Time.zone.parse(slot['inicio']) rescue nil
        end_time = Time.zone.parse(slot['fim']) rescue nil
        duration = ((end_time - start_time) / 60).to_i if start_time && end_time

        next unless professional && room && start_time && duration

        prof_conflict = conflict_for_professional?(professional, start_time, end_time)
        room_conflict = conflict_for_room?(room, start_time, end_time)

        if prof_conflict || room_conflict
          conflicts << { 
            slot: slot, 
            prof_conflict: prof_conflict, 
            room_conflict: room_conflict 
          }
        end
      end
      conflicts
    end
  end
end 