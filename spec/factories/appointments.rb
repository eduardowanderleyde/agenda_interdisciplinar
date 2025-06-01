FactoryBot.define do
  factory :appointment do
    association :professional
    association :patient
    association :room
    association :specialty
    start_time { Time.zone.now.beginning_of_day + 9.hours }
    duration { 30 }
    status { 'scheduled' }
    notes { "Test notes" }

    trait :completed do
      status { 'completed' }
    end

    trait :cancelled do
      status { 'cancelled' }
    end

    trait :with_evolution do
      after(:create) do |appointment|
        create(:evolution, appointment: appointment)
      end
    end
  end
end
