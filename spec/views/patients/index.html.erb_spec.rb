require 'rails_helper'

RSpec.describe "patients/index", type: :view do
  before(:each) do
    assign(:patients, [
      Patient.create!(
        name: "Name",
        diagnosis: "Diagnosis",
        observations: "MyText"
      ),
      Patient.create!(
        name: "Name",
        diagnosis: "Diagnosis",
        observations: "MyText"
      )
    ])
  end

  it "renders a list of patients" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Diagnosis".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
