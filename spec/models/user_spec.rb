require 'rails_helper'

RSpec.describe User, type: :model do
  it 'pode ser admin' do
    user = User.new(email: 'admin@teste.com', password: '123456', role: :admin)
    expect(user.admin?).to be true
    expect(user.profissional?).to be false
  end

  it 'pode ser profissional' do
    user = User.new(email: 'prof@teste.com', password: '123456', role: :profissional)
    expect(user.profissional?).to be true
    expect(user.admin?).to be false
  end

  it 'não é admin nem profissional se role for nil' do
    user = User.new(email: 'x@x.com', password: '123456')
    expect(user.admin?).to be false
    expect(user.profissional?).to be false
  end
end
