class AppointmentsController < ApplicationController
  before_action :require_admin!
  before_action :set_appointment, only: %i[show edit update destroy]

  # GET /appointments or /appointments.json
  def index
    @appointment = Appointment.new

    # Refatoração para modularizar os filtros
    @pagy, @appointments = pagy(
      Appointment.includes(:patient, :professional, :room)
                 .yield_self { |scope| filter_by_professional(scope) }
                 .yield_self { |scope| filter_by_patient(scope) }
                 .yield_self { |scope| filter_by_room(scope) }
                 .yield_self { |scope| filter_by_date(scope) }
                 .order(start_time: :desc)
    )
  end

  # GET /appointments/1 or /appointments/1.json
  def show
  end

  # GET /appointments/new
  def new
    @appointment = Appointment.new
  end

  # GET /appointments/1/edit
  def edit
  end

  # POST /appointments or /appointments.json
  def create
    @appointment = Appointment.new(appointment_params)
    conflict_service = ConflictDetectionService.new

    if conflict_service.any_conflict?(@appointment)
      flash.now[:alert] = 'Conflito de horário detectado.'
      render :new
    elsif @appointment.save
      redirect_to @appointment, notice: 'Agendamento criado com sucesso.'
    else
      render :new
    end
  end

  # PATCH/PUT /appointments/1 or /appointments/1.json
  def update
    conflict_service = ConflictDetectionService.new
    if conflict_service.any_conflict?(@appointment)
      flash.now[:alert] = 'Conflito de horário detectado.'
      render :edit
    elsif @appointment.update(appointment_params)
      redirect_to @appointment, notice: 'Agendamento atualizado com sucesso.'
    else
      render :edit
    end
  end

  # DELETE /appointments/1 or /appointments/1.json
  def destroy
    @appointment.destroy!

    respond_to do |format|
      format.html { redirect_to appointments_path, status: :see_other, notice: 'Agendamento excluído com sucesso.' }
      format.json { head :no_content }
    end
  end

  # POST /appointments/batch_update
  def batch_update
    begin
      ags = params[:agendamentos] || []
      conflict_service = ConflictDetectionService.new
      conflitos = []

      # Validação prévia de todos os agendamentos
      ags.each do |ag|
        if ag["room_id"].blank? || ag["room_id"] == "undefined" ||
           ag["start_time"].blank? || (Time.zone.parse(ag["start_time"]) rescue nil).nil?
          conflitos << {
            agendamento: ag,
            motivo: "Dados inválidos: sala ou horário não selecionados corretamente."
          }
        end
      end

      if conflitos.any?
        render json: { status: 'erro', conflitos: conflitos }, status: 422
        return
      end

      # Só executa se todos os agendamentos são válidos
      if ags.any?
        semana = Date.parse(ags.first["start_time"]).beginning_of_week..Date.parse(ags.first["start_time"]).end_of_week
        Appointment.where(start_time: semana).delete_all
      end

      appointments = ags.map do |ag|
        Appointment.new(
          patient_id: ag["patient_id"],
          professional_id: ag["professional_id"],
          room_id: ag["room_id"],
          start_time: ag["start_time"],
          specialty_id: ag["specialty_id"],
          duration: 30
        )
      end

      conflitos = conflict_service.batch_conflicts(appointments)

      if conflitos.any?
        render json: { status: 'erro', conflitos: conflitos }, status: 422
        return
      end

      appointments.each(&:save!)

      head :ok
    rescue => e
      render json: { status: 'erro', mensagem: "Erro interno: #{e.message}" }, status: 500
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def appointment_params
    params.require(:appointment).permit(:patient_id, :professional_id, :room_id, :start_time, :duration, :status,
                                        :notes, :specialty_id)
  end

  # Filtro por profissional
  def filter_by_professional(scope)
    if params[:professional_id].present?
      scope.where(professional_id: params[:professional_id])
    else
      scope
    end
  end

  # Filtro por paciente
  def filter_by_patient(scope)
    if params[:patient_id].present?
      scope.where(patient_id: params[:patient_id])
    else
      scope
    end
  end

  # Filtro por sala
  def filter_by_room(scope)
    if params[:room_id].present?
      scope.where(room_id: params[:room_id])
    else
      scope
    end
  end

  # Filtro por data
  def filter_by_date(scope)
    if params[:date].present?
      begin
        date = Date.parse(params[:date])
      rescue ArgumentError
        date = nil
      end

      if date
        scope.where(start_time: date.beginning_of_day..date.end_of_day)
      else
        scope
      end
    else
      scope
    end
  end
end
