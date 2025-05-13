class SuggestionsController < ApplicationController
  before_action :require_admin!

  def index
    @patients = Patient.order(:name)
    @rooms = Room.order(:name)
    @specialties = Specialty.order(:name)

    if params[:start_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = start_date + 6.days

      @appointments = Appointment
                      .where(start_time: start_date.beginning_of_day..end_date.end_of_day)
                      .includes(:patient, :professional, :specialty, :room)
                      .order(:room_id, :start_time)
    end

    @selected_patient = params[:patient_id].presence && Patient.find_by(id: params[:patient_id])
    @selected_room = params[:room_id].presence && Room.find_by(id: params[:room_id])
    @selected_specialty = params[:specialty_id].presence && Specialty.find_by(id: params[:specialty_id])

    @week_days = (Date.today.beginning_of_week..Date.today.end_of_week).to_a

    # Gera horários de 07:00 até 19:00 de 30 em 30 minutos
    @hours = []
    (7..18).each do |h|
      @hours << "%02d:00" % h
      @hours << "%02d:30" % h
    end
    @hours << "19:00"

    @suggestions = {}
    # Montar grade vazia: [dia][hora][sala] = nil
    grade = {}
    @week_days.each do |dia|
      grade[dia] = {}
      @hours.each do |hora|
        grade[dia][hora] = {}
        @rooms.each { |sala| grade[dia][hora][sala.id] = nil }
      end
    end

    # Hashes auxiliares para ocupação
    sala_ocupada = Hash.new { |h, k| h[k] = {} } # sala_ocupada[dia][hora][sala_id] = true
    paciente_ocupado = Hash.new { |h, k| h[k] = {} } # paciente_ocupado[dia][hora][patient_id] = true
    profissional_ocupado = Hash.new { |h, k| h[k] = {} } # profissional_ocupado[dia][hora][prof_id] = true

    Patient.includes(:specialties).where(available_this_week: true).order(:name).each do |patient|
      patient.specialties.each do |spec|
        duration = spec.default_duration || 30
        @week_days.each do |dia|
          dia_semana = dia.strftime('%A').downcase
          hora_idx = 0
          while hora_idx < @hours.length
            hora = @hours[hora_idx]
            inicio = Time.zone.parse("#{dia} #{hora}")
            fim = inicio + duration.minutes
            break if fim > Time.zone.parse("#{dia} 19:00")

            professionals_disponiveis = Professional.includes(:specialties).where(available_this_week: true).select do |prof|
              prof.specialty_ids.include?(spec.id) &&
                prof.available_days.include?(dia_semana) &&
                prof.available_hours[dia_semana]&.any? { |intervalo|
                  ini, fim_i = intervalo.split(' - ')
                  ini_t = Time.zone.parse("#{dia} #{ini}")
                  fim_t = Time.zone.parse("#{dia} #{fim_i}")
                  inicio >= ini_t && fim <= fim_t
                }
            end
            if professionals_disponiveis.any?
              sala_livre = @rooms.find do |sala|
                livre = true
                t = inicio
                while t < fim
                  grade[dia][t.strftime('%H:%M')] ||= {}
                  sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                  livre &&= grade[dia][t.strftime('%H:%M')][sala.id].nil?
                  livre &&= !sala_ocupada[dia][t.strftime('%H:%M')][sala.id]
                  t += 30.minutes
                end
                livre
              end
              if sala_livre
                # Marcar todos os slots do intervalo como ocupados para a sala
                t = inicio
                while t < fim
                  sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                  sala_ocupada[dia][t.strftime('%H:%M')][sala_livre.id] = true
                  t += 30.minutes
                end
                profissional = professionals_disponiveis.find do |prof|
                  livre = true
                  t = inicio
                  while t < fim
                    grade[dia][t.strftime('%H:%M')] ||= {}
                    sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                    paciente_ocupado[dia][t.strftime('%H:%M')] ||= {}
                    profissional_ocupado[dia][t.strftime('%H:%M')] ||= {}
                    livre &&= !profissional_ocupado[dia][t.strftime('%H:%M')][prof.id]
                    t += 30.minutes
                  end
                  livre
                end
                if profissional
                  ocupado = false
                  t = inicio
                  while t < fim
                    paciente_ocupado[dia][t.strftime('%H:%M')] ||= {}
                    ocupado ||= paciente_ocupado[dia][t.strftime('%H:%M')][patient.id]
                    t += 30.minutes
                  end
                  unless ocupado
                    t = inicio
                    while t < fim
                      grade[dia][t.strftime('%H:%M')] ||= {}
                      sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                      paciente_ocupado[dia][t.strftime('%H:%M')] ||= {}
                      profissional_ocupado[dia][t.strftime('%H:%M')] ||= {}
                      if grade[dia][t.strftime('%H:%M')][sala_livre.id].nil?
                        grade[dia][t.strftime('%H:%M')][sala_livre.id] = {
                          patient_id: patient.id,
                          patient_name: patient.name,
                          professional_id: profissional.id,
                          professional_name: profissional.name,
                          specialty: spec.name
                        }
                        sala_ocupada[dia][t.strftime('%H:%M')][sala_livre.id] = true
                        paciente_ocupado[dia][t.strftime('%H:%M')][patient.id] = true
                        profissional_ocupado[dia][t.strftime('%H:%M')][profissional.id] = true
                      end
                      t += 30.minutes
                    end
                    Rails.logger.info "ENCAIXADO: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} na sala #{sala_livre.id} com profissional #{profissional.name}"
                    hora_idx += 1
                    break # Sai do loop de horários após encaixar para este paciente/especialidade/dia
                  else
                    Rails.logger.info "OCUPADO: Paciente #{patient.name} (#{spec.name}) já está ocupado em #{dia} #{hora}"
                  end
                else
                  Rails.logger.info "SEM PROFISSIONAL: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} - Nenhum profissional disponível"
                end
              else
                Rails.logger.info "SEM SALA: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} - Nenhuma sala livre"
              end
            else
              Rails.logger.info "SEM PROFISSIONAL DISPONÍVEL: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} - Nenhum profissional disponível no horário"
            end
            hora_idx += 1
          end
        end
      end
    end

    # Preencher @suggestions para a view
    @week_days.each do |dia|
      @suggestions[dia] = {}
      @hours.each do |hora|
        @suggestions[dia][hora] = []
        @rooms.each do |sala|
          ag = grade[dia][hora][sala.id]
          @suggestions[dia][hora] << ag if ag.present?
        end
        # Log de verificação de sobreposição
        if @suggestions[dia][hora].size > 1
          Rails.logger.info "SOBREPOSIÇÃO: #{dia} #{hora} - #{@suggestions[dia][hora].size} agendamentos na mesma sala"
        end
      end
    end
  end

  def dias
    dias = (Date.today..(Date.today + 6.days)).map do |d|
      { value: d.to_s, label: I18n.l(d, format: :long) }
    end
    render json: { dias: dias }
  end

  def horarios
    patient = Patient.find_by(id: params[:patient_id])
    dia = params[:dia]
    horarios = []
    if patient && dia.present?
      # Exemplo: horários disponíveis do paciente para o dia
      horarios = (8..17).map { |h| '%02d:00' % h }
    end
    render json: { horarios: horarios }
  end

  def especialidades
    patient = Patient.find_by(id: params[:patient_id])
    especialidades = patient ? patient.specialties.select(:id, :name) : []
    render json: { especialidades: especialidades }
  end

  def sugestoes
    patient = Patient.find_by(id: params[:patient_id])
    dia = params[:dia]
    horario = params[:horario]
    especialidade_id = params[:especialidade_id]
    profissionais = []
    if patient && dia.present? && horario.present? && especialidade_id.present?
      profissionais = Professional.joins(:specialties)
                                  .where(specialties: { id: especialidade_id })
                                  .select do |prof|
        prof.available_days.include?(Date.parse(dia).strftime('%A').downcase) &&
          prof.available_hours.include?(horario) &&
          Appointment.where(professional: prof)
                     .where('DATE(start_time) = ?', dia)
                     .where('start_time::time = ?', horario)
                     .none?
      end
    end
    render json: {
      profissionais: profissionais.map { |p| { id: p.id, name: p.name } }
    }
  end

  def simulate_schedule
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    end_date = start_date + 6.days
    week_days = (start_date..end_date).to_a
    # Gera horários de 07:00 até 19:00 de 30 em 30 minutos
    hours = []
    (7..18).each do |h|
      hours << "%02d:00" % h
      hours << "%02d:30" % h
    end
    hours << "19:00"
    rooms = Room.order(:name).to_a
    professionals = Professional.includes(:specialties).where(available_this_week: true).to_a
    patients = Patient.includes(:specialties).where(available_this_week: true).to_a
    specialties = Specialty.all.index_by(&:id)

    # Hashes auxiliares para ocupação
    sala_ocupada = Hash.new { |h, k| h[k] = {} }
    paciente_ocupado = Hash.new { |h, k| h[k] = {} }
    profissional_ocupado = Hash.new { |h, k| h[k] = {} }

    # Montar grade vazia: [dia][hora][sala] = nil
    grade = {}
    week_days.each do |dia|
      grade[dia] = {}
      hours.each do |hora|
        grade[dia][hora] = {}
        rooms.each { |sala| grade[dia][hora][sala.id] = nil }
      end
    end

    # Simulação: para cada paciente, tentar encaixar em horários disponíveis com profissional e sala compatíveis
    patients.each do |patient|
      patient.specialties.each do |spec|
        duration = spec.default_duration || 30
        week_days.each do |dia|
          dia_semana = dia.strftime('%A').downcase
          hora_idx = 0
          while hora_idx < hours.length
            hora = hours[hora_idx]
            inicio = Time.zone.parse("#{dia} #{hora}")
            fim = inicio + duration.minutes
            break if fim > Time.zone.parse("#{dia} 19:00")

            professionals_disponiveis = professionals.select do |prof|
              prof.specialty_ids.include?(spec.id) &&
                prof.available_days.include?(dia_semana) &&
                prof.available_hours[dia_semana]&.any? { |intervalo|
                  ini, fim_i = intervalo.split(' - ')
                  ini_t = Time.zone.parse("#{dia} #{ini}")
                  fim_t = Time.zone.parse("#{dia} #{fim_i}")
                  inicio >= ini_t && fim <= fim_t
                }
            end
            if professionals_disponiveis.any?
              sala_livre = rooms.find do |sala|
                livre = true
                t = inicio
                while t < fim
                  grade[dia][t.strftime('%H:%M')] ||= {}
                  sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                  livre &&= grade[dia][t.strftime('%H:%M')][sala.id].nil?
                  livre &&= !sala_ocupada[dia][t.strftime('%H:%M')][sala.id]
                  t += 30.minutes
                end
                livre
              end
              if sala_livre
                # Marcar todos os slots do intervalo como ocupados para a sala
                t = inicio
                while t < fim
                  sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                  sala_ocupada[dia][t.strftime('%H:%M')][sala_livre.id] = true
                  t += 30.minutes
                end
                profissional = professionals_disponiveis.find do |prof|
                  livre = true
                  t = inicio
                  while t < fim
                    grade[dia][t.strftime('%H:%M')] ||= {}
                    sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                    paciente_ocupado[dia][t.strftime('%H:%M')] ||= {}
                    profissional_ocupado[dia][t.strftime('%H:%M')] ||= {}
                    livre &&= !profissional_ocupado[dia][t.strftime('%H:%M')][prof.id]
                    t += 30.minutes
                  end
                  livre
                end
                if profissional
                  ocupado = false
                  t = inicio
                  while t < fim
                    paciente_ocupado[dia][t.strftime('%H:%M')] ||= {}
                    ocupado ||= paciente_ocupado[dia][t.strftime('%H:%M')][patient.id]
                    t += 30.minutes
                  end
                  unless ocupado
                    t = inicio
                    while t < fim
                      grade[dia][t.strftime('%H:%M')] ||= {}
                      sala_ocupada[dia][t.strftime('%H:%M')] ||= {}
                      paciente_ocupado[dia][t.strftime('%H:%M')] ||= {}
                      profissional_ocupado[dia][t.strftime('%H:%M')] ||= {}
                      if grade[dia][t.strftime('%H:%M')][sala_livre.id].nil?
                        grade[dia][t.strftime('%H:%M')][sala_livre.id] = {
                          patient_id: patient.id,
                          patient_name: patient.name,
                          professional_id: profissional.id,
                          professional_name: profissional.name,
                          specialty: spec.name
                        }
                        sala_ocupada[dia][t.strftime('%H:%M')][sala_livre.id] = true
                        paciente_ocupado[dia][t.strftime('%H:%M')][patient.id] = true
                        profissional_ocupado[dia][t.strftime('%H:%M')][profissional.id] = true
                      end
                      t += 30.minutes
                    end
                    Rails.logger.info "ENCAIXADO: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} na sala #{sala_livre.id} com profissional #{profissional.name}"
                    hora_idx += 1
                    break # Sai do loop de horários após encaixar para este paciente/especialidade/dia
                  else
                    Rails.logger.info "OCUPADO: Paciente #{patient.name} (#{spec.name}) já está ocupado em #{dia} #{hora}"
                  end
                else
                  Rails.logger.info "SEM PROFISSIONAL: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} - Nenhum profissional disponível"
                end
              else
                Rails.logger.info "SEM SALA: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} - Nenhuma sala livre"
              end
            else
              Rails.logger.info "SEM PROFISSIONAL DISPONÍVEL: Paciente #{patient.name} (#{spec.name}) em #{dia} #{hora} - Nenhum profissional disponível no horário"
            end
            hora_idx += 1
          end
        end
      end
    end

    render partial: 'simulacao_grade', locals: { grade: grade, week_days: week_days, hours: hours, rooms: rooms }
  end
end
