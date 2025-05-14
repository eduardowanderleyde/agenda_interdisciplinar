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

# Profissionais brasileiros com muita disponibilidade
Professional.destroy_all
def nomes_profissionais
  [
    'Camila Rocha', 'Pedro Lima', 'Fernanda Souza', 'Lucas Almeida', 'Juliana Castro',
    'Rafael Martins', 'Patrícia Oliveira', 'Bruno Carvalho', 'Marina Duarte', 'André Barbosa'
  ]
end

nomes_profissionais.each do |nome|
  Professional.create!(
    name: nome,
    available_days: %w[monday tuesday wednesday thursday friday],
    available_hours: {
      'monday' => ['07:00 - 19:00'],
      'tuesday' => ['07:00 - 19:00'],
      'wednesday' => ['07:00 - 19:00'],
      'thursday' => ['07:00 - 19:00'],
      'friday' => ['07:00 - 19:00']
    },
    available_this_week: true,
    specialties: all_specialties.sample(rand(2..3))
  )
end

# Pacientes brasileiros com responsáveis e diagnósticos reais
Patient.destroy_all
def nomes_pacientes
  [
    'Lucas Silva', 'Ana Beatriz Souza', 'Gabriel Oliveira', 'Mariana Lima', 'Rafael Costa',
    'Isabela Martins', 'Pedro Henrique Alves', 'Lívia Fernandes', 'Matheus Rocha', 'Sofia Cardoso',
    'João Pedro Ribeiro', 'Laura Mendes', 'Enzo Almeida', 'Helena Duarte', 'Gustavo Barbosa'
  ]
end

def nomes_responsaveis
  [
    'Maria da Silva', 'João Pereira', 'Patrícia Souza', 'Carlos Henrique', 'Fernanda Lima',
    'Roberta Castro', 'André Martins', 'Juliana Oliveira', 'Bruno Fernandes', 'Camila Duarte'
  ]
end

diagnosticos = ['TEA', 'TDAH', 'Dislexia', 'Atraso de fala', 'Deficiência Intelectual', 'Transtorno de Ansiedade']

nomes_pacientes.each_with_index do |nome, idx|
  Patient.create!(
    name: nome,
    birthdate: Faker::Date.birthday(min_age: 4, max_age: 16),
    diagnosis: diagnosticos.sample,
    responsible: nomes_responsaveis[idx % nomes_responsaveis.size],
    observations: Faker::Lorem.sentence(word_count: 8),
    available_this_week: true,
    specialties: all_specialties.sample(rand(1..3))
  )
end

Patient.create!(
  name: 'Paciente Teste Disponível',
  birthdate: Date.new(2015, 5, 14),
  diagnosis: 'Teste de disponibilidade',
  responsible: 'Responsável Teste',
  observations: 'Paciente criado para testar disponibilidade de profissionais.',
  available_this_week: true,
  specialties: [Specialty.first]
)

# Usuário admin
User.find_or_create_by!(email: 'admin@example.com') do |user|
  user.password = 'password'
  user.role = 'admin'
end

# Usuário profissional externo
unless User.exists?(email: 'externo@clinica.com')
  User.create!(email: 'externo@clinica.com', password: '123456', role: :profissional)
end

Professional.create!(
  name: 'Profissional Completo',
  specialties: Specialty.all.sample(2),
  available_days: %w[monday tuesday wednesday thursday friday],
  available_hours: {
    'monday' => ['07:00 - 19:00'],
    'tuesday' => ['07:00 - 19:00'],
    'wednesday' => ['07:00 - 19:00'],
    'thursday' => ['07:00 - 19:00'],
    'friday' => ['07:00 - 19:00']
  },
  available_this_week: true
)
