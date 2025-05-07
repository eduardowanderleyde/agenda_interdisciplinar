require 'rails_helper'

RSpec.describe Appointment, type: :model do
  let(:patient) { Patient.create!(name: 'Paciente Teste', birthdate: '2010-01-01', diagnosis: 'TEA', observations: 'Teste') }
  let(:professional) { Professional.create!(name: 'Profissional Teste', specialty: 'Fonoaudiólogo', available_days: %w[monday tuesday], available_hours: %w[08:00 09:00]) }

  it 'é válido com atributos obrigatórios' do
    appointment = Appointment.new(patient: patient, professional: professional, start_time: Time.zone.now, duration: 30, status: 'agendado')
    expect(appointment).to be_valid
  end

  it 'não permite conflito de horário para o mesmo profissional' do
    start_time = Time.zone.local(2024, 5, 7, 8, 0)
    Appointment.create!(patient: patient, professional: professional, start_time: start_time, duration: 60, status: 'agendado')
    conflict = Appointment.new(patient: patient, professional: professional, start_time: start_time + 30.minutes, duration: 30, status: 'agendado')
    expect(conflict).not_to be_valid
    expect(conflict.errors[:base]).to include("Conflito de horário para este profissional.")
  end

  it 'permite agendamentos sem conflito para o mesmo profissional' do
    start_time = Time.zone.local(2024, 5, 7, 8, 0)
    Appointment.create!(patient: patient, professional: professional, start_time: start_time, duration: 30, status: 'agendado')
    no_conflict = Appointment.new(patient: patient, professional: professional, start_time: start_time + 30.minutes, duration: 30, status: 'agendado')
    expect(no_conflict).to be_valid
  end

  it 'pertence a um paciente e a um profissional' do
    appointment = Appointment.new(patient: patient, professional: professional, start_time: Time.zone.now, duration: 30, status: 'agendado')
    expect(appointment.patient).to eq(patient)
    expect(appointment.professional).to eq(professional)
  end
end
