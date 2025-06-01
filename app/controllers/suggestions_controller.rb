class SuggestionsController < ApplicationController
  before_action :require_admin!

  def index
    @patients = Patient.order(:name)
    @rooms = Room.order(:name)
    @specialties = Specialty.order(:name)
    @selected_patients = Patient.where(selected_for_schedule: true)
    # Apenas mostra os filtros e o botão
    @week_days = (Date.today.beginning_of_week..Date.today.end_of_week).to_a
    @hours = (7..18).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['19:00']
    @suggestions = nil
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
    especialidades = patient ? patient.specialties.to_a.select(:id, :name) : []
    render json: { especialidades: especialidades }
  end

  def sugestoes
    patient = Patient.find_by(id: params[:patient_id])
    dia = params[:dia]
    horario = params[:horario]
    especialidade_id = params[:especialidade_id]
    profissionais = []
    if patient && dia.present? && horario.present? && especialidade_id.present?
      dia_semana = Date.parse(dia).strftime('%A').downcase
      profissionais = Professional.joins(:specialties)
                                  .where(specialties: { id: especialidade_id })
                                  .to_a.select do |prof|
        prof.available_days.include?(dia_semana) &&
          prof.available_hours[dia_semana]&.any? do |intervalo|
            ini, fim_i = intervalo.split(' - ')
            Time.zone.parse("#{dia} #{ini}") <= Time.zone.parse("#{dia} #{horario}") &&
              Time.zone.parse("#{dia} #{horario}") < Time.zone.parse("#{dia} #{fim_i}")
          end &&
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
    hours = []
    t = Time.zone.parse('07:00')
    while t <= Time.zone.parse('19:00')
      hours << t.strftime('%H:%M')
      t += 15.minutes
    end
    rooms = if params[:room_id].present?
              Room.where(id: params[:room_id]).to_a
            else
              Room.order(:name).to_a
            end
    grade = {}
    week_days.each do |dia|
      grade[dia] = {}
      hours.each do |hora|
        grade[dia][hora] = {}
        rooms.each { |sala| grade[dia][hora][sala.id] = nil }
      end
    end
    @selected_patients = Patient.where(selected_for_schedule: true)
    respond_to do |format|
      format.html do
        render partial: 'simulacao_grade', locals: { grade: grade, week_days: week_days, hours: hours, rooms: rooms }
      end
      format.json do
        html = render_to_string(partial: 'simulacao_grade', formats: [:html], locals: {
                                  grade: grade,
                                  week_days: week_days,
                                  hours: hours,
                                  rooms: rooms,
                                  tabela_tipo: 'sugestao',
                                  selected_room: rooms.first,
                                  selected_patients: @selected_patients
                                })
        render json: { sugestoes: [], html: html }
      end
    end
  end

  # Nova action para gerar sugestões
  def generate
    @patients = Patient.order(:name)
    @rooms = Room.order(:name)
    @specialties = Specialty.order(:name)
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    end_date = start_date + 6.days
    @week_days = (start_date..end_date).to_a
    @hours = (7..18).flat_map { |h| ['%02d:00' % h, '%02d:30' % h] } + ['19:00']
    @suggestions = {}
    @week_days.each do |dia|
      @suggestions[dia] = {}
      @hours.each { |hora| @suggestions[dia][hora] = [] }
    end
    # --- PROCESSAMENTO PESADO AQUI (copie o loop de sugestões original) ---
    professionals = Professional.includes(:specialties).to_a
    patients = Patient.includes(:specialties).order(:name).to_a
    # ... (copie o processamento de cruzamento de horários aqui, igual ao index original) ...
    render :index
  end

  private

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: 'Acesso não autorizado.'
  end
end
