require 'rails_helper'

RSpec.describe "patients/show", type: :view do
  before(:each) do
    assign(:patient, Patient.create!(
      name: "Name",
      diagnosis: "Diagnosis",
      observations: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Diagnosis/)
    expect(rendered).to match(/MyText/)
  end
end
