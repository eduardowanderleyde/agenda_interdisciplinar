require 'rails_helper'

RSpec.describe "professionals/show", type: :view do
  before(:each) do
    assign(:professional, Professional.create!(
      name: "Name",
      specialty: "Specialty",
      available_days: "",
      available_hours: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Specialty/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
