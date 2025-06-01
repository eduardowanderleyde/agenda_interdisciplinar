class PatientsController < ApplicationController
  before_action :require_admin!
  before_action :set_patient, only: %i[show edit update destroy select_for_schedule]

  # GET /patients or /patients.json
  def index
    @pagy, @patients = pagy(Patient.includes(:specialties).order(:name))
  end

  # GET /patients/1 or /patients/1.json
  def show
  end

  # GET /patients/new
  def new
    @patient = Patient.new
  end

  # GET /patients/1/edit
  def edit
  end

  # POST /patients or /patients.json
  def create
    @patient = Patient.new(patient_params)

    respond_to do |format|
      if @patient.save
        format.html { redirect_to @patient, notice: 'Paciente criado com sucesso.' }
        format.json { render :show, status: :created, location: @patient }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @patient.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /patients/1 or /patients/1.json
  def update
    respond_to do |format|
      if @patient.update(patient_params)
        format.html { redirect_to @patient, notice: 'Paciente atualizado com sucesso.' }
        format.json { render :show, status: :ok, location: @patient }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @patient.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /patients/1 or /patients/1.json
  def destroy
    @patient.destroy!

    respond_to do |format|
      format.html { redirect_to patients_path, status: :see_other, notice: 'Paciente excluído com sucesso.' }
      format.json { head :no_content }
    end
  end

  # PATCH /patients/:id/select_for_schedule
  def select_for_schedule
    @patient = Patient.find(params[:id])
    value = ActiveModel::Type::Boolean.new.cast(params[:selected_for_schedule])
    @patient.update(selected_for_schedule: value)
    head :ok
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_patient
    @patient = Patient.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def patient_params
    params.require(:patient).permit(
      :name, :birthdate, :diagnosis, :responsible, :observations, :available_this_week,
      available_days: [], available_hours: {}, specialty_ids: []
    )
  end
end
