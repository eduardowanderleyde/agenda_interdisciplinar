# frozen_string_literal: true

# Serviço responsável por gerenciar a disponibilidade de profissionais
#
# Este serviço encapsula toda a lógica relacionada à verificação de disponibilidade
# de profissionais, incluindo:
# - Horários disponíveis em um dia específico
# - Profissionais disponíveis para uma sala e horário
# - Disponibilidade semanal de um profissional
#
# @example Verificar horários disponíveis
#   service = ProfessionalAvailabilityService.new(professional)
#   available_times = service.available_times_for(Date.today, 30)
#
# @example Verificar profissionais disponíveis
#   service = ProfessionalAvailabilityService.new
#   available_professionals = service.available_professionals_for(room, Time.now, 30)
#
# @example Verificar disponibilidade semanal
#   service = ProfessionalAvailabilityService.new
#   weekly_availability = service.weekly_availability_for(professional, Date.today..Date.today + 6.days)
class ProfessionalAvailabilityService
  # Inicializa o serviço com um profissional opcional
  #
  # @param professional [Professional] profissional para verificar disponibilidade
  def initialize(professional = nil)
    @professional = professional
  end

  # Retorna os horários disponíveis para um profissional em uma data específica
  #
  # @param date [Date] data para verificar disponibilidade
  # @param duration [Integer] duração em minutos do agendamento
  # @return [Array<String>] array com os horários disponíveis no formato "HH:MM"
  def available_times_for(date, duration)
    return [] unless @professional && date && duration

    Rails.cache.fetch("professional_#{@professional.id}_available_times_#{date}_#{duration}", expires_in: 1.hour) do
      available_hours = @professional.available_hours
      day_of_week = date.strftime('%A').downcase
      return [] unless @professional.available_days.include?(day_of_week)

      booked_times = Appointment.where(professional: @professional)
                              .where('DATE(start_time) = ?', date)
                              .pluck(:start_time, :duration)
                              .map { |start, dur| (start..start + dur.minutes) }

      available_rooms = Room.where(active: true)
      booked_rooms = Appointment.where(room: available_rooms)
                              .where('DATE(start_time) = ?', date)
                              .pluck(:start_time, :duration, :room_id)
                              .map { |start, dur, room_id| [start..start + dur.minutes, room_id] }

      available_times = []
      available_hours.each do |hour|
        start_time = Time.zone.parse("#{date} #{hour}")
        end_time = start_time + duration.minutes

        next if booked_times.any? { |range| range.overlaps?(start_time..end_time) }

        room_available = available_rooms.any? do |room|
          room_bookings = booked_rooms.select { |_, room_id| room_id == room.id }
          room_bookings.none? { |range, _| range.overlaps?(start_time..end_time) }
        end

        available_times << hour if room_available
      end

      available_times
    end
  end

  # Retorna os profissionais disponíveis para uma sala e horário específicos
  #
  # @param room [Room] sala para verificar disponibilidade
  # @param datetime [DateTime] data e hora para verificar disponibilidade
  # @param duration [Integer] duração em minutos do agendamento
  # @return [Array<Professional>] array com os profissionais disponíveis
  def available_professionals_for(room, datetime, duration)
    return [] unless datetime && duration

    Rails.cache.fetch("available_professionals_#{room.id}_#{datetime}_#{duration}", expires_in: 1.hour) do
      Professional.where(available_this_week: true).select do |prof|
        # Verifica se o profissional trabalha neste dia da semana
        prof.available_days.include?(datetime.strftime('%A').downcase) &&
          # Verifica se o profissional tem horário disponível
          prof.available_hours.any? { |h| h.include?(datetime.strftime('%H:%M')) } &&
          # Verifica se não tem conflito de horário
          check_availability(prof, nil, datetime, datetime + duration.minutes)
      end
    end
  end

  # Retorna a disponibilidade semanal de um profissional
  #
  # @param professional [Professional] profissional para verificar disponibilidade
  # @param week_range [Range<Date>] intervalo de datas da semana
  # @return [Hash<String, Array<String>>] hash com os horários e salas disponíveis
  def weekly_availability_for(professional, week_range)
    return {} unless professional && week_range

    Rails.cache.fetch("professional_#{professional.id}_weekly_availability_#{week_range.first}_#{week_range.last}", expires_in: 1.hour) do
      horarios = (8..17).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['18:00']
      horarios_livres = {}

      # Monta hash de ocupação em memória
      prof_busy = Hash.new { |h, k| h[k] = [] }
      room_busy = Hash.new { |h, k| h[k] = [] }
      
      Appointment.where(professional: professional, start_time: week_range).each do |appt|
        prof_busy[professional.id] << (appt.start_time...(appt.start_time + appt.duration.minutes))
        room_busy[appt.room_id] << (appt.start_time...(appt.start_time + appt.duration.minutes)) if appt.room_id
      end

      week_range.each do |dia|
        horarios.each do |hora|
          inicio = Time.zone.parse("#{dia} #{hora}")
          fim = inicio + 30.minutes
          
          # Verifica se o profissional está ocupado
          next if prof_busy[professional.id].any? { |range| range.overlaps?(inicio...fim) }

          # Salas livres
          salas_livres = Room.where(active: true).select do |sala|
            room_busy[sala.id].none? do |range|
              range.overlaps?(inicio...fim)
            end
          end.map(&:name)

          horarios_livres["#{I18n.l(dia, format: '%A')} #{hora}"] = salas_livres if salas_livres.any?
        end
      end

      horarios_livres
    end
  end

  private

  # Verifica se um profissional ou sala está disponível em um horário específico
  #
  # @param professional [Professional] profissional para verificar disponibilidade
  # @param room [Room] sala para verificar disponibilidade
  # @param start_time [DateTime] início do horário
  # @param end_time [DateTime] fim do horário
  # @return [Boolean] true se estiver disponível, false caso contrário
  def check_availability(professional, room, start_time, end_time)
    return false if start_time.nil? || end_time.nil?

    # Verifica se o profissional está disponível
    if professional
      professional_conflict = Appointment.where(professional: professional)
                                       .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?",
                                              end_time, start_time)
                                       .exists?
      return false if professional_conflict
    end

    # Verifica se a sala está disponível
    if room
      room_conflict = Appointment.where(room: room)
                               .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?",
                                      end_time, start_time)
                               .exists?
      return false if room_conflict
    end

    true
  end
end 