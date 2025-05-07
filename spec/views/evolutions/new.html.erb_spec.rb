require 'rails_helper'

RSpec.describe "evolutions/new", type: :view do
  before(:each) do
    assign(:evolution, Evolution.new(
      appointment: nil,
      content: "MyText",
      next_steps: "MyText"
    ))
  end

  it "renders new evolution form" do
    render

    assert_select "form[action=?][method=?]", evolutions_path, "post" do

      assert_select "input[name=?]", "evolution[appointment_id]"

      assert_select "textarea[name=?]", "evolution[content]"

      assert_select "textarea[name=?]", "evolution[next_steps]"
    end
  end
end
