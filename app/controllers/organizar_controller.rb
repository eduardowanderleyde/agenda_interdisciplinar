class OrganizarController < ApplicationController
  def index
    @professionals = Professional.all
    @rooms = Room.all
    @patients = Patient.all

    if params[:professional_id].present? && params[:start_date].present?
      @profissional = Professional.find(params[:professional_id])
      week_start = Date.parse(params[:start_date])
      week_end = week_start + 6.days
      horarios = (8..17).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['18:00']
      @horarios_livres_profissional = {}
      (week_start..week_end).each do |dia|
        horarios.each do |hora|
          inicio = Time.zone.parse("#{dia} #{hora}")
          fim = inicio + 30.minutes
          conflito = Appointment.where(professional: @profissional)
                                .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?", fim, inicio).exists?
          next if conflito

          salas_livres = Room.all.select do |sala|
            !Appointment.where(room: sala)
                        .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?", fim, inicio).exists?
          end.map(&:name)
          @horarios_livres_profissional["#{I18n.l(dia, format: '%A')} #{hora}"] = salas_livres if salas_livres.any?
        end
      end
    elsif params[:patient_id].present? && params[:start_date].present?
      @paciente = Patient.find(params[:patient_id])
      week_start = Date.parse(params[:start_date])
      week_end = week_start + 6.days
      horarios = (8..17).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['18:00']
      @horarios_livres_paciente = {}
      (week_start..week_end).each do |dia|
        horarios.each do |hora|
          inicio = Time.zone.parse("#{dia} #{hora}")
          fim = inicio + 30.minutes
          conflito = Appointment.where(patient: @paciente)
                                .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?", fim, inicio).exists?
          next if conflito

          profissionais_livres = Professional.all.select do |prof|
            !Appointment.where(professional: prof)
                        .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?", fim, inicio).exists?
          end.map(&:name)
          salas_livres = Room.all.select do |sala|
            !Appointment.where(room: sala)
                        .where("start_time < ? AND (start_time + interval '1 minute' * duration) > ?", fim, inicio).exists?
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
      result = `python3 script/organizador.py '#{filtros.to_json}'`
      @agendas = JSON.parse(result)
    else
      @agendas = []
    end

    # --- NOVO BLOCO: Popula agendamentos reais para o planner semanal ---
    return unless params[:start_date].present?

    dias = (0..6).map { |i| Date.parse(params[:start_date]) + i.days }
    @agendamentos_por_sala_e_dia = {}

    Room.all.each do |sala|
      @agendamentos_por_sala_e_dia[sala.id] = {}
      dias.each do |dia|
        ags = Appointment.where(room: sala)
                         .where(start_time: dia.beginning_of_day..dia.end_of_day)
                         .includes(:patient, :professional, :specialty)
                         .order(:start_time)
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

    # --- FIM DO NOVO BLOCO ---
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
