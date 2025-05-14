class AgendaOrganizerService
  def initialize(filtros)
    @start_date = filtros[:start_date]
    @professionals = filtros[:professionals].present? ? Professional.where(id: filtros[:professionals]) : Professional.all
    @rooms = filtros[:rooms].present? ? Room.where(id: filtros[:rooms]) : Room.all
    @session_duration = filtros[:session_duration] || 30
    @week_start = Date.parse(@start_date)
    @week_end = @week_start + 6.days
    # Busca todos os agendamentos da semana de uma vez só
    @appointments = Appointment.where(start_time: @week_start.beginning_of_day..@week_end.end_of_day)
                               .includes(:professional, :room)
  end

  def suggest_agendas
    return [] unless valid_params?

    # Gera 10 opções diferentes de agenda
    (1..10).map do |opcao|
      {
        'opcao' => opcao,
        'descricao' => generate_description(opcao),
        'slots' => generate_realistic_slots
      }
    end
  end

  private

  def valid_params?
    @start_date.present?
  end

  def generate_description(opcao)
    case opcao
    when 1
      'Agenda com horários da manhã'
    when 2
      'Agenda com horários da tarde'
    when 3
      'Agenda distribuída entre manhã e tarde'
    else
      "Agenda alternativa ##{opcao}"
    end
  end

  def generate_realistic_slots
    slots = []
    current_date = @week_start

    # Monta hashes de ocupação em memória
    prof_busy = Hash.new { |h, k| h[k] = [] }
    room_busy = Hash.new { |h, k| h[k] = [] }
    @appointments.each do |appt|
      if appt.professional_id
        prof_busy[appt.professional_id] << (appt.start_time...(appt.start_time + appt.duration.to_i.minutes))
      end
      room_busy[appt.room_id] << (appt.start_time...(appt.start_time + appt.duration.to_i.minutes)) if appt.room_id
    end

    while current_date <= @week_end
      # Horários de trabalho: 8h às 18h
      (8..17).each do |hour|
        [0, 30].each do |minute|
          start_time = Time.zone.parse("#{current_date} #{hour}:#{'%02d' % minute}")
          end_time = start_time + @session_duration.to_i.minutes

          # Pula horário de almoço (12h às 13h)
          next if hour == 12

          available_professionals = @professionals.select do |prof|
            prof.available_days.include?(start_time.strftime('%A').downcase) &&
              prof.available_hours.any? { |h| h.include?(start_time.strftime('%H:%M')) } &&
              prof_busy[prof.id].none? { |range| range.overlaps?(start_time...end_time) }
          end

          available_rooms = @rooms.select do |room|
            room_busy[room.id].none? { |range| range.overlaps?(start_time...end_time) }
          end

          if available_professionals.any? && available_rooms.any?
            slots << {
              'sala' => available_rooms.sample.name,
              'profissional' => available_professionals.sample.name,
              'paciente' => "Paciente #{slots.length + 1}",
              'inicio' => start_time.strftime('%H:%M'),
              'fim' => end_time.strftime('%H:%M'),
              'dia' => current_date.strftime('%d/%m/%Y')
            }
          end

          # Limita a 5 slots por agenda
          break if slots.length >= 5
        end
        break if slots.length >= 5
      end
      current_date += 1
    end

    slots
  end

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

  def get_available_professionals(start_time, end_time)
    return [] unless start_time && end_time

    @professionals.select do |prof|
      # Verifica se o profissional trabalha neste dia da semana
      prof.available_days.include?(start_time.strftime('%A').downcase) &&
        # Verifica se o profissional tem horário disponível
        prof.available_hours.any? { |h| h.include?(start_time.strftime('%H:%M')) } &&
        # Verifica se não tem conflito de horário
        check_availability(prof, nil, start_time, end_time)
    end
  end

  def get_available_rooms(start_time, end_time)
    return [] unless start_time && end_time

    @rooms.select do |room|
      check_availability(nil, room, start_time, end_time)
    end
  end
end
