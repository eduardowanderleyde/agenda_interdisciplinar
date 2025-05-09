class OrganizarController < ApplicationController
  def index
    # Se não houver data selecionada, use o dia atual
    # Permite que paciente_sem_agendamento funcione como patient_id
    params[:patient_id] ||= params[:paciente_sem_agendamento]

    # Se não houver data selecionada, use o dia atual
    params[:start_date] ||= Date.current.to_s
    week_start = Date.parse(params[:start_date])
    week_end = week_start + 6.days

    # Buscar todos os dados necessários em uma única consulta
    @rooms = Room.all
    @appointments = Appointment
                    .where(start_time: week_start.beginning_of_day..week_end.end_of_day)
                    .includes(:patient, :professional, :specialty, :room)
                    .order(:room_id, :start_time)

    @professionals = Professional.all
    @patients = Patient.all

    if params[:professional_id].present? && params[:start_date].present?
      @profissional = Professional.find(params[:professional_id])
      horarios = (8..17).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['18:00']
      @horarios_livres_profissional = {}
      # Monta hash de ocupação em memória
      prof_busy = Hash.new { |h, k| h[k] = [] }
      room_busy = Hash.new { |h, k| h[k] = [] }
      @appointments.each do |appt|
        if appt.professional_id
          prof_busy[appt.professional_id] << (appt.start_time...(appt.start_time + appt.duration.minutes))
        end
        room_busy[appt.room_id] << (appt.start_time...(appt.start_time + appt.duration.minutes)) if appt.room_id
      end
      (week_start..week_end).each do |dia|
        horarios.each do |hora|
          inicio = Time.zone.parse("#{dia} #{hora}")
          fim = inicio + 30.minutes
          # Verifica se o profissional está ocupado
          next if prof_busy[@profissional.id].any? { |range| range.overlaps?(inicio...fim) }

          # Salas livres
          salas_livres = @rooms.select do |sala|
            room_busy[sala.id].none? do |range|
              range.overlaps?(inicio...fim)
            end
          end.map(&:name)
          @horarios_livres_profissional["#{I18n.l(dia, format: '%A')} #{hora}"] = salas_livres if salas_livres.any?
        end
      end
    elsif params[:patient_id].present? && params[:start_date].present?
      @paciente = Patient.find(params[:patient_id])
      @paciente = Patient.find(params[:patient_id] || params[:paciente_sem_agendamento])
      horarios = (8..17).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['18:00']
      @horarios_livres_paciente = {}
      # Monta hash de ocupação em memória
      patient_busy = Hash.new { |h, k| h[k] = [] }
      prof_busy = Hash.new { |h, k| h[k] = [] }
      room_busy = Hash.new { |h, k| h[k] = [] }
      @appointments.each do |appt|
        if appt.patient_id
          patient_busy[appt.patient_id] << (appt.start_time...(appt.start_time + appt.duration.minutes))
        end
        if appt.professional_id
          prof_busy[appt.professional_id] << (appt.start_time...(appt.start_time + appt.duration.minutes))
        end
        room_busy[appt.room_id] << (appt.start_time...(appt.start_time + appt.duration.minutes)) if appt.room_id
      end
      (week_start..week_end).each do |dia|
        horarios.each do |hora|
          inicio = Time.zone.parse("#{dia} #{hora}")
          fim = inicio + 30.minutes
          # Verifica se o paciente está ocupado
          next if patient_busy[@paciente.id].any? { |range| range.overlaps?(inicio...fim) }

          # Profissionais livres (ajustado para considerar especialidade, dia e horário)
          profissionais_livres = @professionals.select do |prof|
            # 1. Está livre nesse horário
            livre = prof_busy[prof.id].none? { |range| range.overlaps?(inicio...fim) }
            # 2. Tem a especialidade desejada
            tem_especialidade = params[:especialidade_id].present? ? prof.specialty_ids.include?(params[:especialidade_id].to_i) : true
            # 3. Atende nesse dia (ajustado para aceitar português e inglês)
            dias_map = {
              'monday' => %w[monday segunda segunda-feira],
              'tuesday' => %W[tuesday ter\u00E7a ter\u00E7a-feira],
              'wednesday' => %w[wednesday quarta quarta-feira],
              'thursday' => %w[thursday quinta quinta-feira],
              'friday' => %w[friday sexta sexta-feira],
              'saturday' => %W[saturday s\u00E1bado sabado],
              'sunday' => %w[sunday domingo]
            }
            dia_semana_en = dia.strftime('%A').downcase # ex: 'monday'
            dia_semana_pt = I18n.l(dia, format: '%A').downcase # ex: 'segunda-feira'
            dias_equivalentes = dias_map[dia_semana_en] || [dia_semana_en, dia_semana_pt]
            atende_dia = (prof.available_days & dias_equivalentes).any?
            # 4. Tem horário disponível nesse intervalo (ajustado para buscar em todos os equivalentes)
            horarios = dias_equivalentes.flat_map { |d| Array(prof.available_hours[d]) }
            duration = params[:duration].presence || prof.default_session_duration || 30
            dentro_do_intervalo = horarios.any? do |intervalo|
              ini_str, fim_str = intervalo.split(' - ')
              ini = begin
                Time.zone.parse("#{dia} #{ini_str}")
              rescue StandardError
                nil
              end
              fim = begin
                Time.zone.parse("#{dia} #{fim_str}")
              rescue StandardError
                nil
              end
              # Verifica se o horário desejado está dentro do intervalo disponível
              # e se há tempo suficiente para a duração do slot
              ini && fim &&
                inicio >= ini &&
                (inicio + duration.to_i.minutes) <= fim
            end
            # LOG
            Rails.logger.info "\n---\nProfissional: #{prof.name}"
            Rails.logger.info "Dias equivalentes: #{dias_equivalentes.inspect}"
            Rails.logger.info "available_days: #{prof.available_days.inspect}"
            Rails.logger.info "Horários disponíveis: #{horarios.inspect}"
            Rails.logger.info "Horário desejado: #{inicio.strftime('%H:%M')}"
            Rails.logger.info "Duração do slot: #{duration} minutos"
            Rails.logger.info "Livre: #{livre}, Tem especialidade: #{tem_especialidade}, Atende dia: #{atende_dia}, Dentro do intervalo: #{dentro_do_intervalo}"
            livre && tem_especialidade && atende_dia && dentro_do_intervalo
          end.map(&:name)
          # Salas livres
          salas_livres = @rooms.select do |sala|
            room_busy[sala.id].none? do |range|
              range.overlaps?(inicio...fim)
            end
          end.map(&:name)
          if profissionais_livres.any? && salas_livres.any?
            @horarios_livres_paciente["#{I18n.l(dia, format: '%A')} #{hora}"] =
              { profissionais: profissionais_livres, salas: salas_livres }
          end
        end
      end
    elsif params[:start_date].present? || params[:professionals].present? || params[:rooms].present? || params[:session_duration].present?
      filtros = {
        start_date: params[:start_date],
        professionals: params[:professionals],
        rooms: params[:rooms],
        session_duration: params[:session_duration]
      }
      @agendas = AgendaOrganizerService.new(filtros).suggest_agendas
    else
      @agendas = []
    end

    # --- NOVO BLOCO OTIMIZADO: Popula agendamentos reais para o planner semanal ---
    return unless params[:start_date].present?

    week_start = Date.parse(params[:start_date])
    week_end = week_start + 6.days
    dias = (week_start..week_end).to_a
    @agendamentos_por_sala_e_dia = {}

    Room.all.each do |sala|
      @agendamentos_por_sala_e_dia[sala.id] = {}
      dias.each do |dia|
        ags = @appointments.select { |ag| ag.room_id == sala.id && ag.start_time.to_date == dia }
        @agendamentos_por_sala_e_dia[sala.id][dia] = ags.map do |ag|
          {
            dia_semana: I18n.l(ag.start_time, format: '%A'),
            hora: ag.start_time.strftime('%H:%M'),
            paciente: ag.patient&.name,
            profissional: ag.professional&.name,
            especialidade: ag.specialty&.name
          }
        end
      end
    end
    # --- FIM DO NOVO BLOCO OTIMIZADO ---
  end

  def escolher
    agenda = params[:agenda].is_a?(String) ? JSON.parse(params[:agenda]) : params[:agenda]
    notes = params[:notes]
    redirect_to organizar_path, alert: 'Agenda inválida.' and return if agenda.blank? || agenda['slots'].blank?

    created = 0
    agenda['slots'].each do |slot|
      professional = Professional.find_by(name: slot['profissional'])
      patient = Patient.find_by(name: slot['paciente'])
      room = Room.find_by(name: slot['sala'])
      start_time = begin
        Time.zone.parse(slot['inicio'])
      rescue StandardError
        nil
      end
      end_time = begin
        Time.zone.parse(slot['fim'])
      rescue StandardError
        nil
      end
      duration = ((end_time - start_time) / 60).to_i if start_time && end_time
      next unless professional && patient && room && start_time && duration

      Appointment.create!(professional: professional, patient: patient, room: room, start_time: start_time,
                          duration: duration, notes: notes)
      created += 1
    end

    redirect_to appointments_path, notice: "#{created} agendamentos criados com sucesso!"
  end

  def confirmar
    @agenda = params[:agenda].is_a?(String) ? JSON.parse(params[:agenda]) : params[:agenda]
    @conflitos = []
    @agenda['slots'].each do |slot|
      professional = Professional.find_by(name: slot['profissional'])
      room = Room.find_by(name: slot['sala'])
      start_time = begin
        Time.zone.parse(slot['inicio'])
      rescue StandardError
        nil
      end
      end_time = begin
        Time.zone.parse(slot['fim'])
      rescue StandardError
        nil
      end
      duration = ((end_time - start_time) / 60).to_i if start_time && end_time
      next unless professional && room && start_time && duration

      # Verifica conflitos de profissional e sala
      prof_conflict = Appointment.where(professional: professional)
                                 .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?", end_time, start_time).exists?
      room_conflict = Appointment.where(room: room)
                                 .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?", end_time, start_time).exists?
      if prof_conflict || room_conflict
        @conflitos << { slot: slot, prof_conflict: prof_conflict, room_conflict: room_conflict }
      end
    end
  end
end
