require 'rails_helper'

RSpec.describe "evolutions/edit", type: :view do
  let(:evolution) {
    Evolution.create!(
      appointment: nil,
      content: "MyText",
      next_steps: "MyText"
    )
  }

  before(:each) do
    assign(:evolution, evolution)
  end

  it "renders the edit evolution form" do
    render

    assert_select "form[action=?][method=?]", evolution_path(evolution), "post" do

      assert_select "input[name=?]", "evolution[appointment_id]"

      assert_select "textarea[name=?]", "evolution[content]"

      assert_select "textarea[name=?]", "evolution[next_steps]"
    end
  end
end
