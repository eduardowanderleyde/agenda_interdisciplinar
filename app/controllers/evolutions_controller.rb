class EvolutionsController < ApplicationController
  before_action :set_evolution, only: %i[ show edit update destroy ]
  before_action :authorize_evolution!

  # GET /evolutions or /evolutions.json
  def index
    @evolutions = Evolution.all
  end

  # GET /evolutions/1 or /evolutions/1.json
  def show
  end

  # GET /evolutions/new
  def new
    @evolution = Evolution.new
  end

  # GET /evolutions/1/edit
  def edit
  end

  # POST /evolutions or /evolutions.json
  def create
    @evolution = Evolution.new(evolution_params)

    respond_to do |format|
      if @evolution.save
        format.html { redirect_to @evolution, notice: "Evolution was successfully created." }
        format.json { render :show, status: :created, location: @evolution }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @evolution.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /evolutions/1 or /evolutions/1.json
  def update
    respond_to do |format|
      if @evolution.update(evolution_params)
        format.html { redirect_to @evolution, notice: "Evolution was successfully updated." }
        format.json { render :show, status: :ok, location: @evolution }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @evolution.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /evolutions/1 or /evolutions/1.json
  def destroy
    @evolution.destroy!

    respond_to do |format|
      format.html { redirect_to evolutions_path, status: :see_other, notice: "Evolution was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_evolution
      @evolution = Evolution.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def evolution_params
      params.require(:evolution).permit(:appointment_id, :content, :next_steps)
    end

    def authorize_evolution!
      return if current_user.admin?
      if action_name.in?(%w[show edit update destroy])
        return if @evolution.appointment.professional.user_id == current_user.id
      end
      if action_name.in?(%w[new create]) && params[:appointment_id]
        appointment = Appointment.find(params[:appointment_id])
        return if appointment.professional.user_id == current_user.id
      end
      redirect_to root_path, alert: "Acesso restrito à evolução do seu atendimento." and return
    end
end
