require 'rails_helper'

RSpec.describe "appointments/edit", type: :view do
  let(:appointment) {
    Appointment.create!(
      patient: nil,
      professional: nil,
      duration: 1,
      status: "MyString",
      notes: "MyText"
    )
  }

  before(:each) do
    assign(:appointment, appointment)
  end

  it "renders the edit appointment form" do
    render

    assert_select "form[action=?][method=?]", appointment_path(appointment), "post" do

      assert_select "input[name=?]", "appointment[patient_id]"

      assert_select "input[name=?]", "appointment[professional_id]"

      assert_select "input[name=?]", "appointment[duration]"

      assert_select "input[name=?]", "appointment[status]"

      assert_select "textarea[name=?]", "appointment[notes]"
    end
  end
end
