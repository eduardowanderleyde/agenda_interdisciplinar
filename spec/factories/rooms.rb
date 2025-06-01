FactoryBot.define do
  factory :room do
    sequence(:name) { |n| "Sala #{n}" }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end 