FactoryBot.define do
  factory :patient do
    name { "MyString" }
    birthdate { "2025-05-06" }
    diagnosis { "MyString" }
    observations { "MyText" }
  end
end
