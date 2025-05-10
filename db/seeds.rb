require 'faker'

# Criar especialidades
specialties = [
  { name: 'Psicologia ABA', description: 'Atendimento psicológico com abordagem ABA', default_duration: 45 },
  { name: 'Psicopedagogia', description: 'Avaliação e intervenção psicopedagógica', default_duration: 60 },
  { name: 'Musicoterapia', description: 'Terapia através da música', default_duration: 45 },
  { name: 'Psicomotricidade', description: 'Trabalho corporal e motor', default_duration: 30 },
  { name: 'Terapia ocupacional AVD', description: 'Atividades de Vida Diária', default_duration: 45 },
  { name: 'Terapia Ocupacional IS', description: 'Integração sensorial', default_duration: 60 },
  { name: 'Fonoaudiologia', description: 'Avaliação e intervenção fonoaudiológica', default_duration: 30 },
  { name: 'Fisioterapia', description: 'Avaliação e intervenção fisioterapêutica', default_duration: 45 }
]

# Limpar registros antigos na ordem correta
Appointment.destroy_all
ProfessionalSpecialty.destroy_all
PatientSpecialty.destroy_all
Specialty.destroy_all
specialties.each do |specialty|
  Specialty.find_or_create_by!(name: specialty[:name]) do |s|
    s.description = specialty[:description]
    s.default_duration = specialty[:default_duration]
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
    available_hours: ['08:00 - 12:00', '13:00 - 17:00'].sample(rand(1..2))
  )

  # Adicionar especialidades aleatórias (garantido que existam)
  professional.specialties << all_specialties.sample(rand(1..3))
end

# Garante que a especialidade "Acompanhamento" exista
acompanhamento = Specialty.find_or_create_by!(name: 'Acompanhamento') do |s|
  s.description = 'Acompanhamento geral'
  s.default_duration = 45
end

# Atualiza lista de especialidades (sempre incluindo Acompanhamento)
all_specialties = Specialty.all.to_a
all_specialties << acompanhamento unless all_specialties.any? { |s| s.name == 'Acompanhamento' }

# Criar pacientes fakes
Patient.destroy_all
10.times do
  # Sorteia outras especialidades (sem incluir "Acompanhamento" para evitar duplicidade)
  outras = all_specialties.reject { |s| s.name == 'Acompanhamento' }
  specialties_for_patient = outras.sample(rand(0..[3, outras.size].min))
  # Sempre inclui "Acompanhamento"
  specialty_ids = [acompanhamento.id] + specialties_for_patient.map(&:id)

  Patient.create!(
    name: Faker::Name.name,
    birthdate: Faker::Date.birthday(min_age: 3, max_age: 18),
    diagnosis: ['TEA', 'TDAH', 'Dislexia', 'Atraso de fala'].sample,
    observations: Faker::Lorem.sentence(word_count: 8),
    specialty_ids: specialty_ids
  )
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

    # Tenta criar o agendamento até 5 vezes, verificando conflito de horário
    success = false
    5.times do
      Appointment.create!(
        patient: patient,
        professional: professional,
        room: room,
        start_time: start_time,
        duration: duration,
        status: %w[agendado realizado cancelado].sample,
        notes: Faker::Lorem.sentence(word_count: 6),
        specialty: patient.specialties.sample
      )
      success = true
      break
    rescue ActiveRecord::RecordInvalid => e
      # Se houver conflito, tenta outro horário
      day = Faker::Date.between(from: 3.days.ago, to: 7.days.from_now)
      hour = [8, 9, 10, 14, 15, 16].sample
      start_time = Time.zone.local(day.year, day.month, day.day, hour, [0, 30].sample)
    end
    # Se não conseguiu após 5 tentativas, pula para o próximo agendamento
    next unless success
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
