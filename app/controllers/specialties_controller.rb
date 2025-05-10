class SpecialtiesController < ApplicationController
  before_action :require_admin!
  before_action :set_specialty, only: %i[show edit update destroy]

  def index
    @pagy, @specialties = pagy(Specialty.all)
  end

  def show
  end

  def new
    @specialty = Specialty.new
  end

  def edit
  end

  def create
    @specialty = Specialty.new(specialty_params)

    respond_to do |format|
      if @specialty.save
        format.html { redirect_to @specialty, notice: 'Especialidade criada com sucesso.' }
        format.json { render :show, status: :created, location: @specialty }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @specialty.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @specialty.update(specialty_params)
        format.html { redirect_to @specialty, notice: 'Especialidade atualizada com sucesso.' }
        format.json { render :show, status: :ok, location: @specialty }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @specialty.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @specialty.destroy!

    respond_to do |format|
      format.html { redirect_to specialties_path, status: :see_other, notice: 'Especialidade excluída com sucesso.' }
      format.json { head :no_content }
    end
  end

  private

  def set_specialty
    @specialty = Specialty.find(params[:id])
  end

  def specialty_params
    params.require(:specialty).permit(:name, :description, :default_duration)
  end
end
