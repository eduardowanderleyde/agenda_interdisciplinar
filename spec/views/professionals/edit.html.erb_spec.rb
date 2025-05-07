require 'rails_helper'

RSpec.describe "professionals/edit", type: :view do
  let(:professional) {
    Professional.create!(
      name: "MyString",
      specialty: "MyString",
      available_days: "",
      available_hours: ""
    )
  }

  before(:each) do
    assign(:professional, professional)
  end

  it "renders the edit professional form" do
    render

    assert_select "form[action=?][method=?]", professional_path(professional), "post" do

      assert_select "input[name=?]", "professional[name]"

      assert_select "input[name=?]", "professional[specialty]"

      assert_select "input[name=?]", "professional[available_days]"

      assert_select "input[name=?]", "professional[available_hours]"
    end
  end
end
