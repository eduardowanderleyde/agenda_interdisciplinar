class AppointmentsController < ApplicationController
  before_action :require_admin!
  before_action :set_appointment, only: %i[show edit update destroy]

  # GET /appointments or /appointments.json
  def index
    @appointment = Appointment.new
    @pagy, @appointments = pagy(
      Appointment.includes(:patient, :professional, :room)
                 .where(nil)
                 .yield_self { |scope| params[:professional_id].present? ? scope.where(professional_id: params[:professional_id]) : scope }
                 .yield_self { |scope| params[:patient_id].present? ? scope.where(patient_id: params[:patient_id]) : scope }
                 .yield_self { |scope| params[:room_id].present? ? scope.where(room_id: params[:room_id]) : scope }
                 .yield_self do |scope|
                   if params[:date].present?
                     date = begin
                       Date.parse(params[:date])
                     rescue StandardError
                       nil
                     end
                     date ? scope.where(start_time: date.beginning_of_day..date.end_of_day) : scope
                   else
                     scope
                   end
                 end
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

    respond_to do |format|
      if @appointment.save
        format.html { redirect_to @appointment, notice: 'Agendamento criado com sucesso.' }
        format.json { render :show, status: :created, location: @appointment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @appointment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /appointments/1 or /appointments/1.json
  def update
    respond_to do |format|
      if @appointment.update(appointment_params)
        format.html { redirect_to @appointment, notice: 'Agendamento atualizado com sucesso.' }
        format.json { render :show, status: :ok, location: @appointment }
        format.turbo_stream
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @appointment.errors, status: :unprocessable_entity }
      end
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

      ags.each do |ag|
        inicio = Time.zone.parse(ag["start_time"])
        fim = inicio + 30.minutes

        conflito = Appointment.exists?([
          "(room_id = :room AND ((start_time, (start_time + (duration * interval '1 minute'))) OVERLAPS (:inicio, :fim))) OR\n \
           (professional_id = :prof AND ((start_time, (start_time + (duration * interval '1 minute'))) OVERLAPS (:inicio, :fim))) OR\n \
           (patient_id = :pac AND ((start_time, (start_time + (duration * interval '1 minute'))) OVERLAPS (:inicio, :fim)))",
          {
            room: ag["room_id"],
            prof: ag["professional_id"],
            pac: ag["patient_id"],
            inicio: inicio,
            fim: fim
          }
        ])

        if conflito
          conflitos << {
            patient_id: ag["patient_id"],
            professional_id: ag["professional_id"],
            room_id: ag["room_id"],
            start_time: ag["start_time"],
            specialty_id: ag["specialty_id"],
            motivo: "Conflito de sala, profissional ou paciente no horário"
          }
          next
        end

        Appointment.create!(
          patient_id: ag["patient_id"],
          professional_id: ag["professional_id"],
          room_id: ag["room_id"],
          start_time: ag["start_time"],
          specialty_id: ag["specialty_id"],
          duration: 30
        )
      end

      if conflitos.any?
        render json: { status: 'erro', conflitos: conflitos }, status: 422
        return
      end

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
end
