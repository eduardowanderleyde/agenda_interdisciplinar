require 'rails_helper'

RSpec.describe ProfessionalAvailabilityService do
  let(:professional) { create(:professional, available_days: ['monday'], available_hours: { 'monday' => ['08:00 - 12:00'] }) }
  let(:room) { create(:room, active: true) }
  let(:service) { described_class.new(professional) }

  describe '#available_times_for' do
    let(:date) { Date.new(2024, 3, 4) } # Segunda-feira
    let(:duration) { 30 }

    context 'quando o profissional está disponível' do
      before do
        allow(professional).to receive(:available_days).and_return(['monday'])
        allow(professional).to receive(:available_hours).and_return({ 'monday' => ['08:00 - 12:00'] })
      end

      it 'retorna horários disponíveis' do
        times = service.available_times_for(date, duration)
        expect(times).to include('08:00', '08:30', '09:00')
      end

      it 'não retorna horários fora do período disponível' do
        times = service.available_times_for(date, duration)
        expect(times).not_to include('13:00', '14:00')
      end
    end

    context 'quando o profissional não está disponível no dia' do
      before do
        allow(professional).to receive(:available_days).and_return(['tuesday'])
      end

      it 'retorna array vazio' do
        times = service.available_times_for(date, duration)
        expect(times).to be_empty
      end
    end
  end

  describe '#available_professionals_for' do
    let(:datetime) { Time.zone.parse('2024-03-04 09:00') }
    let(:duration) { 30 }

    context 'quando há profissionais disponíveis' do
      let!(:available_professional) do
        create(:professional,
               available_days: ['monday'],
               available_hours: { 'monday' => ['08:00 - 12:00'] },
               available_this_week: true)
      end

      it 'retorna profissionais disponíveis' do
        professionals = service.available_professionals_for(room, datetime, duration)
        expect(professionals).to include(available_professional)
      end
    end

    context 'quando não há profissionais disponíveis' do
      let!(:unavailable_professional) do
        create(:professional,
               available_days: ['tuesday'],
               available_hours: { 'tuesday' => ['08:00 - 12:00'] },
               available_this_week: true)
      end

      it 'retorna array vazio' do
        professionals = service.available_professionals_for(room, datetime, duration)
        expect(professionals).to be_empty
      end
    end
  end

  describe '#weekly_availability_for' do
    let(:week_range) { Date.new(2024, 3, 4)..Date.new(2024, 3, 8) }

    context 'quando o profissional tem disponibilidade na semana' do
      before do
        allow(professional).to receive(:available_days).and_return(['monday', 'wednesday'])
        allow(professional).to receive(:available_hours).and_return({
          'monday' => ['08:00 - 12:00'],
          'wednesday' => ['14:00 - 18:00']
        })
      end

      it 'retorna horários disponíveis para cada dia' do
        availability = service.weekly_availability_for(professional, week_range)
        expect(availability).to include(
          'segunda-feira 08:00',
          'segunda-feira 08:30',
          'quarta-feira 14:00',
          'quarta-feira 14:30'
        )
      end

      it 'não retorna horários indisponíveis' do
        availability = service.weekly_availability_for(professional, week_range)
        expect(availability).not_to include(
          'terça-feira 08:00',
          'quinta-feira 14:00'
        )
      end
    end

    context 'quando o profissional não tem disponibilidade na semana' do
      before do
        allow(professional).to receive(:available_days).and_return(['saturday'])
      end

      it 'retorna hash vazio' do
        availability = service.weekly_availability_for(professional, week_range)
        expect(availability).to be_empty
      end
    end
  end
end 