require 'rails_helper'

RSpec.describe Patient, type: :model do
  subject { described_class.new(name: 'João', birthdate: Date.new(2015, 5, 7), diagnosis: 'TEA') }

  it 'é válido com atributos obrigatórios' do
    expect(subject).to be_valid
  end

  it 'inválido sem nome' do
    subject.name = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:name]).to include("can't be blank").or include('não pode ficar em branco')
  end

  it 'inválido sem data de nascimento' do
    subject.birthdate = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:birthdate]).to include("can't be blank").or include('não pode ficar em branco')
  end

  it 'inválido sem diagnóstico' do
    subject.diagnosis = nil
    expect(subject).not_to be_valid
    expect(subject.errors[:diagnosis]).to include("can't be blank").or include('não pode ficar em branco')
  end
end
