class ProfessionalsController < ApplicationController
  before_action :require_admin!
  before_action :set_professional, only: %i[show edit update destroy schedule available_times]

  # GET /professionals or /professionals.json
  def index
    @professionals = Professional.all
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
    @week_days = (Date.today.beginning_of_week..Date.today.end_of_week).to_a
    @appointments = @professional.appointments.where(start_time: @week_days.first.beginning_of_day..@week_days.last.end_of_day)
  end

  def available_times
    date = Date.parse(params[:date])
    duration = params[:duration].to_i

    # Horários disponíveis do profissional
    available_hours = @professional.available_hours
    day_of_week = date.strftime('%A').downcase
    return render json: { times: [] } unless @professional.available_days.include?(day_of_week)

    # Horários já agendados
    booked_times = Appointment.where(professional: @professional)
                              .where('DATE(start_time) = ?', date)
                              .pluck(:start_time, :duration)
                              .map { |start, dur| (start..start + dur.minutes) }

    # Salas disponíveis
    available_rooms = Room.where(active: true)
    booked_rooms = Appointment.where(room: available_rooms)
                              .where('DATE(start_time) = ?', date)
                              .pluck(:start_time, :duration, :room_id)
                              .map { |start, dur, room_id| [start..start + dur.minutes, room_id] }

    # Filtrar horários disponíveis
    available_times = []
    available_hours.each do |hour|
      start_time = Time.zone.parse("#{date} #{hour}")
      end_time = start_time + duration.minutes

      # Verificar se o profissional está disponível
      next if booked_times.any? { |range| range.overlaps?(start_time..end_time) }

      # Verificar se há sala disponível
      room_available = available_rooms.any? do |room|
        room_bookings = booked_rooms.select { |_, room_id| room_id == room.id }
        room_bookings.none? { |range, _| range.overlaps?(start_time..end_time) }
      end

      available_times << hour if room_available
    end

    render json: { times: available_times }
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
