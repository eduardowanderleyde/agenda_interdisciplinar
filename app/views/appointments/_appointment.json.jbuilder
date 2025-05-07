json.extract! appointment, :id, :patient_id, :professional_id, :start_time, :duration, :status, :notes, :created_at, :updated_at
json.url appointment_url(appointment, format: :json)
