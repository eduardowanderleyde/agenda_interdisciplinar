FactoryBot.define do
  factory :professional do
    sequence(:name) { |n| "Profissional #{n}" }
    available_days { ['monday', 'wednesday', 'friday'] }
    available_hours do
      {
        'monday' => ['08:00 - 12:00', '14:00 - 18:00'],
        'wednesday' => ['08:00 - 12:00', '14:00 - 18:00'],
        'friday' => ['08:00 - 12:00', '14:00 - 18:00']
      }
    end
    default_session_duration { 30 }
    available_this_week { true }

    trait :unavailable do
      available_this_week { false }
    end

    trait :with_specialties do
      after(:create) do |professional|
        create_list(:specialty, 2, professionals: [professional])
      end
    end
  end
end
