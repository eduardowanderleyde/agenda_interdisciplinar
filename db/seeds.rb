# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'faker'

# Criar especialidades
specialties = [
  { name: 'Psicologia ABA', description: 'Atendimento psicológico com abordagem ABA' },
  { name: 'Psicopedagogia', description: 'Avaliação e intervenção psicopedagógica' },
  { name: 'Musicoterapia', description: 'Terapia através da música' },
  { name: 'Psicomotricidade', description: 'Trabalho corporal e motor' },
  { name: 'Terapia ocupacional AVD', description: 'Atividades de Vida Diária' },
  { name: 'Terapia Ocupacional IS', description: 'Integração sensorial' },
  { name: 'Fonoaudiologia', description: 'Avaliação e intervenção fonoaudiológica' },
  { name: 'Fisioterapia', description: 'Avaliação e intervenção fisioterapêutica' }
]

Specialty.destroy_all
specialties.each do |specialty|
  Specialty.find_or_create_by!(name: specialty[:name]) do |s|
    s.description = specialty[:description]
  end
end

# Atualizar variáveis após recriação
all_specialties = Specialty.all.to_a

# Criar salas
Room.destroy_all
12.times do |i|
  Room.find_or_create_by!(name: "Sala #{i + 1}") do |room|
    room.description = "Sala de atendimento #{i + 1}"
    room.active = true
  end
end

# Criar profissionais fakes
Professional.destroy_all
5.times do
  professional = Professional.create!(
    name: Faker::Name.name,
    available_days: %w[monday tuesday wednesday thursday friday].sample(3),
    available_hours: ['08:00', '09:00', '10:00', '14:00', '15:00', '16:00'].sample(4)
  )

  # Adicionar especialidades aleatórias (garantido que existam)
  professional.specialties << all_specialties.sample(rand(1..3))
end

# Criar pacientes fakes
Patient.destroy_all
10.times do
  patient = Patient.create!(
    name: Faker::Name.name,
    birthdate: Faker::Date.birthday(min_age: 3, max_age: 18),
    diagnosis: ['TEA', 'TDAH', 'Dislexia', 'Atraso de fala'].sample,
    observations: Faker::Lorem.sentence(word_count: 8)
  )

  # Adicionar especialidades necessárias
  patient.specialties << all_specialties.sample(rand(1..4))
end

# Criar agendamentos fakes
if Patient.any? && Professional.any? && Room.any?
  Appointment.destroy_all
  20.times do
    patient = Patient.order('RANDOM()').first
    professional = Professional.order('RANDOM()').first
    room = Room.order('RANDOM()').first
    day = Faker::Date.between(from: 3.days.ago, to: 7.days.from_now)
    hour = [8, 9, 10, 14, 15, 16].sample
    start_time = Time.zone.local(day.year, day.month, day.day, hour, [0, 30].sample)
    duration = [30, 45, 60].sample

    Appointment.create!(
      patient: patient,
      professional: professional,
      room: room,
      start_time: start_time,
      duration: duration,
      status: %w[agendado realizado cancelado].sample,
      notes: Faker::Lorem.sentence(word_count: 6)
    )
  end
end

# Usuário admin
User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.role = 'admin'
end

# Usuário profissional externo
unless User.exists?(email: 'externo@clinica.com')
  User.create!(email: 'externo@clinica.com', password: '123456',
               role: :profissional)
end
