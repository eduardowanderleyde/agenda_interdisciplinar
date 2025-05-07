FactoryBot.define do
  factory :evolution do
    association :appointment
    content { "Test evolution content" }
    next_steps { "Test next steps" }
  end
end
