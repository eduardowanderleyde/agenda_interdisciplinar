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

    @hours = ['08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00']

    @suggestions = {}

    return unless @selected_patient

    specialties = @selected_specialty ? [@selected_specialty] : @selected_patient.specialties

    @week_days.each do |day|
      @suggestions[day] = {}
      @hours.each do |hour|
        @suggestions[day][hour] = []
        @rooms.each do |room|
          next if @selected_room && room != @selected_room

          # Verifica se a sala está livre
          sala_livre = Appointment.where(room: room)
                                  .where('DATE(start_time) = ?', day)
                                  .where('start_time::time = ?', hour)
                                  .none?

          # Verifica se o paciente está livre
          paciente_livre = Appointment.where(patient: @selected_patient)
                                      .where('DATE(start_time) = ?', day)
                                      .where('start_time::time = ?', hour)
                                      .none?

          # Verifica se o profissional está livre e tem a especialidade
          profissional_livre = specialties.any? do |spec|
            Professional.joins(:specialties)
                        .where(specialties: { id: spec.id })
                        .any? do |prof|
              prof.available_days.include?(day.strftime('%A').downcase) &&
                prof.available_hours.include?(hour) &&
                Appointment.where(professional: prof)
                           .where('DATE(start_time) = ?', day)
                           .where('start_time::time = ?', hour)
                           .none?
            end
          end

          # Se a sala, paciente e profissional estiverem livres, adiciona à sugestão
          @suggestions[day][hour] << room if sala_livre && paciente_livre && profissional_livre
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
    # Parâmetros opcionais: data de início da semana
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    end_date = start_date + 6.days
    week_days = (start_date..end_date).to_a
    hours = ['08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00']
    rooms = Room.order(:name).to_a
    professionals = Professional.includes(:specialties).to_a
    patients = Patient.includes(:specialties).to_a
    specialties = Specialty.all.index_by(&:id)

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
        week_days.each do |dia|
          dia_semana = dia.strftime('%A').downcase
          hours.each do |hora|
            professionals_disponiveis = professionals.select do |prof|
              prof.specialty_ids.include?(spec.id) &&
                prof.available_days.include?(dia_semana) &&
                prof.available_hours[dia_semana]&.any? { |intervalo|
                  ini, fim = intervalo.split(' - ')
                  hora >= ini && hora < fim
                }
            end
            next if professionals_disponiveis.empty?
            sala_livre = rooms.find { |sala| grade[dia][hora][sala.id].nil? }
            next unless sala_livre
            profissional = professionals_disponiveis.find do |prof|
              # Profissional não pode estar ocupado nesse horário/sala
              rooms.all? { |sala|
                grade[dia][hora][sala.id].nil? || grade[dia][hora][sala.id][:professional_id] != prof.id
              }
            end
            next unless profissional
            # Paciente não pode estar ocupado nesse horário
            ocupado = rooms.any? { |sala| grade[dia][hora][sala.id]&.dig(:patient_id) == patient.id }
            next if ocupado
            # Encaixa!
            grade[dia][hora][sala_livre.id] = {
              patient_id: patient.id,
              patient_name: patient.name,
              professional_id: profissional.id,
              professional_name: profissional.name,
              specialty: spec.name
            }
            break # Só um agendamento por paciente por horário
          end
        end
      end
    end

    # Renderizar a grade como partial HTML
    render partial: 'simulacao_grade', locals: { grade: grade, week_days: week_days, hours: hours, rooms: rooms }
  end
end
