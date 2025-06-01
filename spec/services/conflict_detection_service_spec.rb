require 'rails_helper'

RSpec.describe ConflictDetectionService do
  let(:service) { described_class.new }
  let(:professional) { create(:professional) }
  let(:patient) { create(:patient) }
  let(:room) { create(:room) }
  let(:start_time) { Time.zone.parse('2024-03-04 09:00') }
  let(:end_time) { start_time + 30.minutes }

  describe '#conflict_for_professional?' do
    context 'quando há conflito de horário' do
      before do
        create(:appointment,
               professional: professional,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna true' do
        expect(service.conflict_for_professional?(professional, start_time, end_time)).to be true
      end
    end

    context 'quando não há conflito de horário' do
      before do
        create(:appointment,
               professional: professional,
               start_time: start_time + 1.hour,
               duration: 30)
      end

      it 'retorna false' do
        expect(service.conflict_for_professional?(professional, start_time, end_time)).to be false
      end
    end
  end

  describe '#conflict_for_patient?' do
    context 'quando há conflito de horário' do
      before do
        create(:appointment,
               patient: patient,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna true' do
        expect(service.conflict_for_patient?(patient, start_time, end_time)).to be true
      end
    end

    context 'quando não há conflito de horário' do
      before do
        create(:appointment,
               patient: patient,
               start_time: start_time + 1.hour,
               duration: 30)
      end

      it 'retorna false' do
        expect(service.conflict_for_patient?(patient, start_time, end_time)).to be false
      end
    end
  end

  describe '#conflict_for_room?' do
    context 'quando há conflito de horário' do
      before do
        create(:appointment,
               room: room,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna true' do
        expect(service.conflict_for_room?(room, start_time, end_time)).to be true
      end
    end

    context 'quando não há conflito de horário' do
      before do
        create(:appointment,
               room: room,
               start_time: start_time + 1.hour,
               duration: 30)
      end

      it 'retorna false' do
        expect(service.conflict_for_room?(room, start_time, end_time)).to be false
      end
    end
  end

  describe '#any_conflict?' do
    let(:appointment) do
      build(:appointment,
            professional: professional,
            patient: patient,
            room: room,
            start_time: start_time,
            duration: 30)
    end

    context 'quando há conflito com profissional' do
      before do
        create(:appointment,
               professional: professional,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna true' do
        expect(service.any_conflict?(appointment)).to be true
      end
    end

    context 'quando há conflito com paciente' do
      before do
        create(:appointment,
               patient: patient,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna true' do
        expect(service.any_conflict?(appointment)).to be true
      end
    end

    context 'quando há conflito com sala' do
      before do
        create(:appointment,
               room: room,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna true' do
        expect(service.any_conflict?(appointment)).to be true
      end
    end

    context 'quando não há conflitos' do
      it 'retorna false' do
        expect(service.any_conflict?(appointment)).to be false
      end
    end
  end

  describe '#batch_conflicts' do
    let(:appointments) do
      [
        build(:appointment,
              professional: professional,
              patient: patient,
              room: room,
              start_time: start_time,
              duration: 30),
        build(:appointment,
              professional: professional,
              patient: patient,
              room: room,
              start_time: start_time + 1.hour,
              duration: 30)
      ]
    end

    context 'quando há conflitos' do
      before do
        create(:appointment,
               professional: professional,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna array com conflitos' do
        conflicts = service.batch_conflicts(appointments)
        expect(conflicts).not_to be_empty
        expect(conflicts.first).to include(
          professional_id: professional.id,
          room_id: room.id,
          start_time: start_time
        )
      end
    end

    context 'quando não há conflitos' do
      it 'retorna array vazio' do
        expect(service.batch_conflicts(appointments)).to be_empty
      end
    end
  end

  describe '#check_agenda_conflicts' do
    let(:agenda) do
      {
        'slots' => [
          {
            'profissional' => professional.name,
            'sala' => room.name,
            'inicio' => start_time.strftime('%Y-%m-%d %H:%M'),
            'fim' => end_time.strftime('%Y-%m-%d %H:%M')
          }
        ]
      }
    end

    context 'quando há conflitos' do
      before do
        create(:appointment,
               professional: professional,
               room: room,
               start_time: start_time,
               duration: 30)
      end

      it 'retorna array com conflitos' do
        conflicts = service.check_agenda_conflicts(agenda)
        expect(conflicts).not_to be_empty
        expect(conflicts.first).to include(
          slot: agenda['slots'].first,
          prof_conflict: true,
          room_conflict: true
        )
      end
    end

    context 'quando não há conflitos' do
      it 'retorna array vazio' do
        expect(service.check_agenda_conflicts(agenda)).to be_empty
      end
    end
  end
end 