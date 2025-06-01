class OrganizarController < ApplicationController
  def index
    @rooms = Room.where(active: true)
    @patients = Patient.all
    @professionals = Professional.all
    @specialties = Specialty.all

    # 1) Determina a data de início da semana (ou a data selecionada)
    if params[:start_date].present?
      begin
        start_date = Date.parse(params[:start_date])
      rescue ArgumentError
        start_date = Date.today.beginning_of_week
      end
    else
      start_date = Date.today.beginning_of_week
    end
    end_date = start_date + 6.days

    # 2) Monta array com cada dia da semana (Date)
    @week_days = (start_date..end_date).to_a

    # 3) Monta o array de horários de 15 em 15 minutos das 07:00 até 19:00
    @hours = []
    start_min = 7 * 60   # 07:00 em minutos
    end_min   = 19 * 60  # 19:00 em minutos
    (start_min..end_min).step(15) do |min|
      h = (min / 60).to_i
      m = (min % 60).to_i
      @hours << "%02d:%02d" % [h, m]
    end

    # 4) Busca todos os appointments da semana (em UTC) e já inclui associações
    semana_inicio_utc = start_date.beginning_of_day.utc
    semana_fim_utc    = end_date.end_of_day.utc
    @appointments = Appointment
                      .where(start_time: semana_inicio_utc..semana_fim_utc)
                      .includes(:patient, :professional, :specialty, :room)
                      .order(:room_id, :start_time)

    # 5) Monta o hash @grades_por_sala com horário local (Time.zone) para cada sala
    @grades_por_sala = {}
    @rooms.each do |sala|
      grade = {}

      # Inicializa grade vazia: para cada dia e cada hora, valor nil
      @week_days.each do |dia|
        grade[dia] = {}
        @hours.each do |hora|
          grade[dia][hora] = nil
        end
      end

      # Preenche com cada appointment daquela sala, convertendo start_time para o fuso local
      @appointments.where(room_id: sala.id).each do |appt|
        appt_local = appt.start_time.in_time_zone(Time.zone)
        data_local = appt_local.to_date                 # ex: 2025-05-31
        hora_min   = appt_local.strftime("%H:%M")        # ex: "11:00"

        if grade.key?(data_local) && grade[data_local].key?(hora_min)
          grade[data_local][hora_min] = {
            patient_name:      appt.patient&.name,
            professional_name: appt.professional&.name,
            patient_id:        appt.patient_id,
            professional_id:   appt.professional_id,
            specialty_id:      appt.specialty_id
          }
        end
      end

      @grades_por_sala[sala.id] = grade
    end

    # 6) Seleções opcionais vindas de params (para filtros de paciente, sala, especialidade)
    @selected_patient   = params[:patient_id].presence && Patient.find_by(id: params[:patient_id])
    @selected_room      = @rooms.find { |r| r.id.to_s == params[:room_id].to_s } || @rooms.first
    @selected_specialty = params[:specialty_id].presence && Specialty.find_by(id: params[:especialidade_id])

    # 7) Se foi selecionado um profissional e data, calcula disponibilidade semanal do profissional
    if params[:professional_id].present? && params[:start_date].present?
      @profissional = Professional.find(params[:professional_id])
      availability_service = ProfessionalAvailabilityService.new(@profissional)
      @horarios_livres_profissional = availability_service.weekly_availability_for(
        @profissional,
        start_date..end_date
      )
    end

    # 8) Se foi selecionado um paciente e uma data, calcula horários livres de paciente, profissionais e salas
    if params[:patient_id].present? && params[:start_date].present?
      @paciente        = Patient.find_by(id: params[:patient_id])
      @data            = Date.parse(params[:start_date])
      @horario         = params[:horario]
      @especialidade_id = params[:especialidade_id]

      # Para each dia da semana e horário, verifica se paciente, profissionais e salas estão livres
      @total_profissionais_checados = Professional.count
      availability_service = ProfessionalAvailabilityService.new
      @profissionais_disponiveis = availability_service.available_professionals_for(
        @selected_room,
        Time.zone.parse("#{@data} #{@horario}"),
        30
      )

      @checagem_profissionais = []
      profissionais = Professional.all
      profissionais.each do |prof|
        @checagem_profissionais << {
          nome: prof.name,
          disponivel: @profissionais_disponiveis.include?(prof),
          motivos: [] # Aqui você pode preencher com critérios de rejeição, se quiser
        }
      end

      # Monta lista de horários possíveis: 08:00 às 18:00 (a cada 30 min)
      horarios = (8..17).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['18:00']
      @horarios_livres_paciente = {}

      week_start = @data.beginning_of_week
      week_end   = @data.end_of_week

      @week_days.each do |dia|
        horarios.each do |hora|
          inicio = Time.zone.parse("#{dia} #{hora}")
          fim    = inicio + 30.minutes

          conflict_service = ConflictDetectionService.new

          # Verifica se o paciente está ocupado
          paciente_ocupado = conflict_service.conflict_for_patient?(@paciente, inicio, fim)
          next if paciente_ocupado

          # Filtra profissionais que já estão disponíveis para esse paciente/hora
          profissionais_livres = @profissionais_disponiveis.select do |prof|
            prof_livre = !conflict_service.conflict_for_professional?(prof, inicio, fim)

            # Verifica se o profissional atende nesse dia e hora
            dia_semana = dia.strftime('%A').downcase
            atende_dia = prof.available_days.include?(dia_semana)
            atende_horario = false
            if prof.available_hours[dia_semana].present?
              prof.available_hours[dia_semana].each do |intervalo|
                ini_str, fim_str = intervalo.split(' - ')
                ini_t = Time.zone.parse("#{dia} #{ini_str}")
                fim_t = Time.zone.parse("#{dia} #{fim_str}")
                if inicio >= ini_t && fim <= fim_t
                  atende_horario = true
                  break
                end
              end
            end

            prof_livre && atende_dia && atende_horario
          end.map(&:name)

          # Filtra salas livres
          salas_livres = @rooms.select do |sala|
            !conflict_service.conflict_for_room?(sala, inicio, fim)
          end.map(&:name)

          if profissionais_livres.any? && salas_livres.any?
            chave = "#{I18n.l(dia, format: '%A')} #{hora}"
            @horarios_livres_paciente[chave] = {
              profissionais: profissionais_livres,
              salas:         salas_livres
            }
          end
        end
      end
    end
  end

  def escolher
    @agenda = params[:agenda].is_a?(String) ? JSON.parse(params[:agenda]) : params[:agenda]
    conflict_service = ConflictDetectionService.new
    @conflitos = conflict_service.check_agenda_conflicts(@agenda)
  end

  def confirmar
    @agenda = params[:agenda].is_a?(String) ? JSON.parse(params[:agenda]) : params[:agenda]
    conflict_service = ConflictDetectionService.new
    @conflitos = conflict_service.check_agenda_conflicts(@agenda)
  end
end
