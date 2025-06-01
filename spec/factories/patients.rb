FactoryBot.define do
  factory :patient do
    sequence(:name) { |n| "Paciente #{n}" }
    sequence(:email) { |n| "paciente#{n}@exemplo.com" }
    sequence(:phone) { |n| "(11) 9#{n.to_s.rjust(8, '0')}" }
    available_this_week { true }

    trait :unavailable do
      available_this_week { false }
    end
  end
end
