FactoryBot.define do
  factory :evolution do
    association :appointment
    sequence(:description) { |n| "Evolução #{n}" }
    sequence(:notes) { |n| "Observações da evolução #{n}" }
    created_at { Time.zone.now }
  end
end
