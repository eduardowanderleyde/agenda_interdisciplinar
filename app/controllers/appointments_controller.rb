class AppointmentsController < ApplicationController
  before_action :require_admin!
  before_action :set_appointment, only: %i[show edit update destroy]

  # GET /appointments or /appointments.json
  def index
    @appointment = Appointment.new
    @appointments = Appointment.includes(:patient, :professional, :room).all
    @appointments = @appointments.where(professional_id: params[:professional_id]) if params[:professional_id].present?
    @appointments = @appointments.where(patient_id: params[:patient_id]) if params[:patient_id].present?
    @appointments = @appointments.where(room_id: params[:room_id]) if params[:room_id].present?
    return unless params[:date].present?

    date = begin
      Date.parse(params[:date])
    rescue StandardError
      nil
    end
    return unless date

    @appointments = @appointments.where(start_time: date.beginning_of_day..date.end_of_day)
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
