FactoryBot.define do
  factory :appointment do
    association :patient
    association :professional
    start_time { Time.current }
    duration { 60 }
    status { "scheduled" }
    notes { "Test notes" }
  end
end
