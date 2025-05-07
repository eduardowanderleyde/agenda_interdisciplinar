require 'rails_helper'

RSpec.describe "appointments/index", type: :view do
  before(:each) do
    assign(:appointments, [
      Appointment.create!(
        patient: nil,
        professional: nil,
        duration: 2,
        status: "Status",
        notes: "MyText"
      ),
      Appointment.create!(
        patient: nil,
        professional: nil,
        duration: 2,
        status: "Status",
        notes: "MyText"
      )
    ])
  end

  it "renders a list of appointments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Status".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
