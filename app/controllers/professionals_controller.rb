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

    respond_to do |format|
      if @professional.save
        format.html { redirect_to @professional, notice: 'Profissional criado com sucesso.' }
        format.json { render :show, status: :created, location: @professional }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @professional.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /professionals/1 or /professionals/1.json
  def update
    respond_to do |format|
      if @professional.update(professional_params)
        format.html { redirect_to @professional, notice: 'Profissional atualizado com sucesso.' }
        format.json { render :show, status: :ok, location: @professional }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @professional.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /professionals/1 or /professionals/1.json
  def destroy
    @professional.destroy!

    respond_to do |format|
      format.html { redirect_to professionals_path, status: :see_other, notice: 'Profissional excluído com sucesso.' }
      format.json { head :no_content }
    end
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
      available_hours = @professional.available_hours
      day_of_week = date.strftime('%A').downcase
      return render json: { times: [] } unless @professional.available_days.include?(day_of_week)

      booked_times = Appointment.where(professional: @professional)
                                .where('DATE(start_time) = ?', date)
                                .pluck(:start_time, :duration)
                                .map { |start, dur| (start..start + dur.minutes) }

      available_rooms = Room.where(active: true)
      booked_rooms = Appointment.where(room: available_rooms)
                                .where('DATE(start_time) = ?', date)
                                .pluck(:start_time, :duration, :room_id)
                                .map { |start, dur, room_id| [start..start + dur.minutes, room_id] }

      available_times = []
      available_hours.each do |hour|
        start_time = Time.zone.parse("#{date} #{hour}")
        end_time = start_time + duration.minutes

        next if booked_times.any? { |range| range.overlaps?(start_time..end_time) }

        room_available = available_rooms.any? do |room|
          room_bookings = booked_rooms.select { |_, room_id| room_id == room.id }
          room_bookings.none? { |range, _| range.overlaps?(start_time..end_time) }
        end

        available_times << hour if room_available
      end

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

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_professional
    @professional = Professional.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def professional_params
    params.require(:professional).permit(
      :name,
      :default_session_duration,
      available_days: [],
      available_hours: {},
      specialty_ids: []
    ).tap do |whitelisted|
      whitelisted[:available_days]&.reject!(&:blank?)
    end
  end
end
