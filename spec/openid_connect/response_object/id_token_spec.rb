require 'spec_helper'

describe OpenIDConnect::ResponseObject::IdToken do
  let(:klass) { OpenIDConnect::ResponseObject::IdToken }
  let(:id_token) { klass.new attributes }
  let :required_attributes do
    {
      :iss => 'https://server.example.com',
      :user_id => 'user_id',
      :aud => 'client_id',
      :exp => 1313424327
    }
  end

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [:iss, :user_id, :aud, :exp] }
    its(:optional_attributes) { should == [:iso29115, :nonce, :issued_to, :secret] }
  end

  describe '#to_jwt' do
    subject { id_token.to_jwt }

    context 'when secret is given' do
      let(:attributes) { required_attributes.merge(:secret => 'secret') }
      it { should be_a String }
    end

    context 'otherwise' do
      let(:attributes) { required_attributes }
      it do
        expect { id_token.to_jwt }.should raise_error OpenIDConnect::Exception, 'Secret Required'
      end
    end
  end

  describe '#as_json' do
    subject { id_token.as_json }
    let(:attributes) { required_attributes.merge(:secret => 'secret') }
    it { should_not include :secret }
  end

  describe '.from_jwt' do
    subject { klass.from_jwt id_token.to_jwt, 'secret' }
    let(:attributes) { required_attributes.merge(:secret => 'secret') }
    it { should be_a klass }
    [:iss, :user_id, :aud, :exp, :secret].each do |key|
      its(key) { should == attributes[key] }
    end
  end
end