require 'rails_helper'

RSpec.describe "professionals/index", type: :view do
  before(:each) do
    assign(:professionals, [
      Professional.create!(
        name: "Name",
        specialty: "Specialty",
        available_days: "",
        available_hours: ""
      ),
      Professional.create!(
        name: "Name",
        specialty: "Specialty",
        available_days: "",
        available_hours: ""
      )
    ])
  end

  it "renders a list of professionals" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Specialty".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
  end
end
