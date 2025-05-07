class SuggestionsController < ApplicationController
  before_action :require_admin!

  def index
    @patients = Patient.order(:name)
    @rooms = Room.order(:name)
    @specialties = Specialty.order(:name)

    @selected_patient = params[:patient_id].presence && Patient.find_by(id: params[:patient_id])
    @selected_room = params[:room_id].presence && Room.find_by(id: params[:room_id])
    @selected_specialty = params[:specialty_id].presence && Specialty.find_by(id: params[:specialty_id])

    @week_days = (Date.today.beginning_of_week..Date.today.end_of_week).to_a
    @hours = ['08:00', '09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00']

    @suggestions = {}
    return unless @selected_patient

    specialties = @selected_specialty ? [@selected_specialty] : @selected_patient.specialties
    @week_days.each do |day|
      @suggestions[day] = {}
      @hours.each do |hour|
        @suggestions[day][hour] = []
        @rooms.each do |room|
          next if @selected_room && room != @selected_room

          sala_livre = Appointment.where(room: room)
                                  .where('DATE(start_time) = ?', day)
                                  .where('start_time::time = ?', hour)
                                  .none?
          paciente_livre = Appointment.where(patient: @selected_patient)
                                      .where('DATE(start_time) = ?', day)
                                      .where('start_time::time = ?', hour)
                                      .none?
          profissional_livre = specialties.any? do |spec|
            Professional.joins(:specialties)
                        .where(specialties: { id: spec.id })
                        .select { |prof| prof.available_days.include?(day.strftime('%A').downcase) && prof.available_hours.include?(hour) }
                        .any? do |prof|
              Appointment.where(professional: prof)
                         .where('DATE(start_time) = ?', day)
                         .where('start_time::time = ?', hour)
                         .none?
            end
          end
          @suggestions[day][hour] << room if sala_livre && paciente_livre && profissional_livre
        end
      end
    end
  end
end
