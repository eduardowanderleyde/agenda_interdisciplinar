require 'rails_helper'

RSpec.describe "patients/edit", type: :view do
  let(:patient) {
    Patient.create!(
      name: "MyString",
      diagnosis: "MyString",
      observations: "MyText"
    )
  }

  before(:each) do
    assign(:patient, patient)
  end

  it "renders the edit patient form" do
    render

    assert_select "form[action=?][method=?]", patient_path(patient), "post" do

      assert_select "input[name=?]", "patient[name]"

      assert_select "input[name=?]", "patient[diagnosis]"

      assert_select "textarea[name=?]", "patient[observations]"
    end
  end
end
