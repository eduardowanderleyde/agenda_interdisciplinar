json.extract! patient, :id, :name, :birthdate, :diagnosis, :observations, :created_at, :updated_at
json.url patient_url(patient, format: :json)
