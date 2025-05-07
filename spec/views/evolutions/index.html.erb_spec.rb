require 'rails_helper'

RSpec.describe "evolutions/index", type: :view do
  before(:each) do
    assign(:evolutions, [
      Evolution.create!(
        appointment: nil,
        content: "MyText",
        next_steps: "MyText"
      ),
      Evolution.create!(
        appointment: nil,
        content: "MyText",
        next_steps: "MyText"
      )
    ])
  end

  it "renders a list of evolutions" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
