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

      # Filtro por paciente, se selecionado
      @appointments = @appointments.where(patient_id: params[:patient_id]) if params[:patient_id].present?

      @professionals = Professional.all.to_a

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
      elsif params[:patient_id].present? && params[:start_date].present? && params[:horario].present?
        @paciente = Patient.find_by(id: params[:patient_id] || params[:paciente_sem_agendamento])
        unless @paciente
          @profissionais_disponiveis = []
          @total_profissionais_checados = 0
          flash.now[:alert] = 'Paciente não encontrado. Selecione novamente.'
          return
        end
        @data = Date.parse(params[:start_date])
        @horario = params[:horario]
        profissionais = @professionals
        especialidade_id = params[:especialidade_id].presence
        dia_semana_pt = I18n.l(@data, format: '%A').downcase # Ex: 'segunda-feira'
        @profissionais_disponiveis = profissionais.select do |prof|
          atende_dia = prof.available_days.include?(dia_semana_pt)
          atende_horario = prof.available_hours[dia_semana_pt]&.any? do |intervalo|
            ini, fim_i = intervalo.split(' - ')
            ini_t = Time.zone.parse("#{@data} #{ini}")
            fim_t = Time.zone.parse("#{@data} #{fim_i}")
            horario_t = Time.zone.parse("#{@data} #{@horario}")
            horario_t >= ini_t && horario_t < fim_t
          end
          tem_especialidade = especialidade_id.present? ? prof.specialties.exists?(id: especialidade_id) : true
          Rails.logger.info "Profissional: #{prof.name} | Especialidade: #{tem_especialidade} | Dia: #{atende_dia} | Horário: #{atende_horario}"
            # LOG para debug
          Rails.logger.info "---"
          Rails.logger.info "Profissional: #{prof.name}"
          Rails.logger.info "available_days: #{prof.available_days.inspect}"
          Rails.logger.info "available_hours[#{dia_semana_pt}]: #{prof.available_hours[dia_semana_pt].inspect}"
          Rails.logger.info "Horário pedido: #{@horario} (#{horario_t.strftime('%H:%M') rescue 'erro'})"
          Rails.logger.info "Atende dia? #{atende_dia} | Atende horário? #{atende_horario} | Tem especialidade? #{tem_especialidade}"
          atende_dia && atende_horario && tem_especialidade
        end
        @total_profissionais_checados = profissionais.size

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
              tem_especialidade = params[:especialidade_id].present? ? prof.specialties.exists?(id: params[:especialidade_id].to_i) : true
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
      if params[:start_date].present?
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
                hora: "#{ag.start_time.strftime('%H:%M')} - #{(ag.start_time + ag.duration.minutes).strftime('%H:%M')}",
                paciente: ag.patient&.name,
                profissional: ag.professional&.name,
                especialidade: ag.specialty&.name
              }
            end
          end
        end

        # Montar grades para cada sala para uso na view
        horarios = []
        t = Time.zone.parse('07:00')
        while t <= Time.zone.parse('19:00')
          horarios << t.strftime('%H:%M')
          t += 15.minutes
        end
        @grades_por_sala = {}
        @rooms.each do |sala|
          @grades_por_sala[sala.id] = montar_grade_para_sala(sala, dias, horarios, @appointments)
        end
      end
      # --- FIM DO NOVO BLOCO OTIMIZADO ---

      # Se paciente e data foram selecionados, buscar disponibilidade de profissionais
      @disponibilidade_profissionais = {}
      return unless params[:patient_id].present? && params[:start_date].present?

      paciente = Patient.find_by(id: params[:patient_id])
      data = Date.parse(params[:start_date])
      horarios = []
      t = Time.zone.parse('07:00')
      while t <= Time.zone.parse('19:00')
        horarios << t.strftime('%H:%M')
        t += 15.minutes
      end
      ids_especialidades = paciente.specialties.pluck(:id)
      profissionais = Professional.joins(:professional_specialties)
                                  .where(professional_specialties: { specialty_id: ids_especialidades })
                                  .to_a.uniq { |p| p.id }

      @total_profissionais_checados = profissionais.size
      Rails.logger.info("Total de profissionais checados: #{@total_profissionais_checados}")

      @profissionais_disponiveis = profissionais.select do |prof|
        inicio = Time.zone.parse("#{data} 07:00")
        fim = Time.zone.parse("#{data} 19:00")
        prof_livre = Appointment.where(professional_id: prof.id, start_time: inicio..fim).none?
        # Verifica se o profissional atende nesse dia e horário
        dia_semana = data.strftime('%A').downcase
        atende_dia = prof.available_days.include?(dia_semana)
        atende_horario = prof.available_hours[dia_semana]&.any? do |intervalo|
          ini, fim_i = intervalo.split(' - ')
          ini_t = Time.zone.parse("#{data} #{ini}")
          fim_t = Time.zone.parse("#{data} #{fim_i}")
          inicio >= ini_t && fim <= fim_t
        end
        prof_livre && atende_dia && atende_horario
      end
      Rails.logger.info "Profissionais disponíveis encontrados: #{@profissionais_disponiveis.size}"

      horarios.each do |hora|
        inicio = Time.zone.parse("#{data} #{hora}")
        fim = inicio + 15.minutes
        # Verifica se o paciente está livre nesse horário
        paciente_ocupado = Appointment.exists?(patient_id: paciente.id, start_time: inicio..fim)
        next if paciente_ocupado

        profissionais_livres = @profissionais_disponiveis.select do |prof|
          prof_livre = Appointment.where(professional_id: prof.id, start_time: inicio..fim).none?
          # Verifica se o profissional atende nesse dia e horário
          dia_semana = data.strftime('%A').downcase
          atende_dia = prof.available_days.include?(dia_semana)
          atende_horario = prof.available_hours[dia_semana]&.any? do |intervalo|
            ini, fim_i = intervalo.split(' - ')
            ini_t = Time.zone.parse("#{data} #{ini}")
            fim_t = Time.zone.parse("#{data} #{fim_i}")
            inicio >= ini_t && fim <= fim_t
          end
          prof_livre && atende_dia && atende_horario
        end
        @disponibilidade_profissionais[hora] = profissionais_livres.map(&:name)
      end

      if params[:patient_id].present?
        @paciente = Patient.find_by(id: params[:patient_id])
        @especialidades_paciente = @paciente&.specialties || []
      else
        @especialidades_paciente = []
      end
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

    private

    def montar_grade_para_sala(sala, dias, horarios, appointments)
      grade = {}
      dias.each do |dia|
        grade[dia] = {}
        horarios.each do |hora|
          agendamento = appointments.find do |a|
            a.room_id == sala.id && a.start_time.to_date == dia && a.start_time.strftime('%H:%M') == hora
          end
          ag = nil
          if agendamento
            ag = {
              patient_id: agendamento.patient_id,
              patient_name: agendamento.patient&.name,
              professional_id: agendamento.professional_id,
              professional_name: agendamento.professional&.name,
              specialty_id: agendamento.specialty_id,
              specialty: agendamento.specialty&.name
            }
          end
          grade[dia][hora] = { sala.id => ag }
        end
      end
      grade
    end
  end
