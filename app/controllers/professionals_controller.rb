class ProfessionalsController < ApplicationController
  before_action :require_admin!
  before_action :set_professional, only: %i[show edit update destroy schedule available_times update_available_this_week]

  # GET /professionals or /professionals.json
  def index
    @pagy, @professionals = pagy(Professional.order(:name))
  end

  # GET /professionals/1 or /professionals/1.json
  def show
  end

  # GET /professionals/new
  def new
    @professional = Professional.new
  end

  # GET /professionals/1/edit
  def edit
  end

  # POST /professionals or /professionals.json
  def create
    @professional = Professional.new(professional_params)

    if @professional.save
      redirect_to @professional, notice: 'Profissional criado com sucesso.'
    else
      render :new
    end
  end

  # PATCH/PUT /professionals/1 or /professionals/1.json
  def update
    if @professional.update(professional_params)
      redirect_to @professional, notice: 'Profissional atualizado com sucesso.'
    else
      render :edit
    end
  end

  # DELETE /professionals/1 or /professionals/1.json
  def destroy
    @professional.destroy!
    redirect_to professionals_path, status: :see_other, notice: 'Profissional excluído com sucesso.'
  end

  def schedule
    # Se vier o parâmetro week, usa ele como referência; senão, usa a semana atual
    ref_date = params[:week].present? ? Date.parse(params[:week]) : Date.today
    week_start = ref_date.beginning_of_week
    week_end = ref_date.end_of_week
    @week_days = (week_start..week_end).to_a
    @appointments = @professional.appointments.where(start_time: week_start.beginning_of_day..week_end.end_of_day)
    @prev_week = (week_start - 7.days).strftime('%Y-%m-%d')
    @next_week = (week_start + 7.days).strftime('%Y-%m-%d')
  end

  def available_times
    unless params[:date].present?
      return render json: { times: [], error: "Parâmetro obrigatório 'date' ausente" }, status: :ok
    end
    unless params[:duration].present?
      return render json: { times: [], error: "Parâmetro obrigatório 'duration' ausente" }, status: :ok
    end

    begin
      date = Date.parse(params[:date])
      duration = params[:duration].to_i
      
      availability_service = ProfessionalAvailabilityService.new(@professional)
      available_times = availability_service.available_times_for(date, duration)
      
      render json: { times: available_times }
    rescue StandardError => e
      Rails.logger.error("Erro em available_times: #{e.message}\n#{e.backtrace.join("\n")}")
      render json: { times: [], error: e.message }, status: :ok
    end
  end

  # PATCH /professionals/:id/available_this_week
  def update_available_this_week
    value = ActiveModel::Type::Boolean.new.cast(params[:available_this_week])
    Rails.logger.info "PATCH available_this_week: params=#{params[:available_this_week].inspect}, casted=#{value.inspect}"
    @professional.update(available_this_week: value)
    head :ok
  end

  def working_hours
    unless params[:date].present?
      return render json: { times: [], error: "Parâmetro obrigatório 'date' ausente" }, status: :ok
    end
    begin
      date = Date.parse(params[:date])
      day_of_week = date.strftime('%A').downcase
      hours = @professional.available_hours[day_of_week] || []
      times = []
      hours.each do |interval|
        ini, fim = interval.split(' - ')
        current = Time.zone.parse("#{date} #{ini}")
        end_time = Time.zone.parse("#{date} #{fim}")
        while current < end_time
          times << current.strftime('%H:%M')
          current += 30.minutes
        end
      end
      render json: { times: times }
    rescue StandardError => e
      Rails.logger.error("Erro em working_hours: #{e.message}\n#{e.backtrace.join("\n")}")
      render json: { times: [], error: e.message }, status: :ok
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_professional
    @professional = Professional.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def professional_params
    dias_pt_en = {
      'segunda-feira' => 'monday',
      'terça-feira' => 'tuesday',
      'quarta-feira' => 'wednesday',
      'quinta-feira' => 'thursday',
      'sexta-feira' => 'friday',
      'sábado' => 'saturday',
      'domingo' => 'sunday'
    }
    params.require(:professional).permit(
      :name,
      :default_session_duration,
      available_days: [],
      available_hours: {},
      specialty_ids: []
    ).tap do |whitelisted|
      whitelisted[:available_days]&.reject!(&:blank?)
      # Conversão automática de dias em português para inglês
      if whitelisted[:available_days].present?
      whitelisted[:available_days] = whitelisted[:available_days].map { |d| dias_pt_en[d] || d }
      end
      # Também converte as chaves de available_hours, se necessário
      if whitelisted[:available_hours].is_a?(Hash)
        whitelisted[:available_hours] = whitelisted[:available_hours].transform_keys { |k| dias_pt_en[k] || k }
      end
    end
  end
end
