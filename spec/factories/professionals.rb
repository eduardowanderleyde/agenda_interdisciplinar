FactoryBot.define do
  factory :professional do
    sequence(:name) { |n| "Professional #{n}" }
    sequence(:specialty) { |n| "Specialty #{n}" }
    available_days { ["Monday", "Wednesday", "Friday"] }
    association :user, factory: :user
  end
end
