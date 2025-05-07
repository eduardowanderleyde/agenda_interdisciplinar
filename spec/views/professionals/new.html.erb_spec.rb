require 'rails_helper'

RSpec.describe "professionals/new", type: :view do
  before(:each) do
    assign(:professional, Professional.new(
      name: "MyString",
      specialty: "MyString",
      available_days: "",
      available_hours: ""
    ))
  end

  it "renders new professional form" do
    render

    assert_select "form[action=?][method=?]", professionals_path, "post" do

      assert_select "input[name=?]", "professional[name]"

      assert_select "input[name=?]", "professional[specialty]"

      assert_select "input[name=?]", "professional[available_days]"

      assert_select "input[name=?]", "professional[available_hours]"
    end
  end
end
