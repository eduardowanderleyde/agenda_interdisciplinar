FactoryBot.define do
  factory :specialty do
    sequence(:name) { |n| "Especialidade #{n}" }
    sequence(:code) { |n| "ESP#{n}" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_professionals do
      after(:create) do |specialty|
        create_list(:professional, 2, specialties: [specialty])
      end
    end
  end
end 