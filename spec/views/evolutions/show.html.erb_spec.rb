require 'rails_helper'

RSpec.describe "evolutions/show", type: :view do
  before(:each) do
    assign(:evolution, Evolution.create!(
      appointment: nil,
      content: "MyText",
      next_steps: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
  end
end
