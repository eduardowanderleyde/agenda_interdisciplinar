require 'rails_helper'

RSpec.describe "Sortears", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/sortear/index"
      expect(response).to have_http_status(:success)
    end
  end

end
