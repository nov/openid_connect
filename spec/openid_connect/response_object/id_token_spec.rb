require 'spec_helper'

describe OpenIDConnect::ResponseObject::IdToken do
  let(:klass) { OpenIDConnect::ResponseObject::IdToken }
  let(:id_token) { klass.new attributes }
  let(:attributes) { required_attributes }
  let(:ext) { 10.minutes.from_now }
  let :required_attributes do
    {
      :iss => 'https://server.example.com',
      :user_id => 'user_id',
      :aud => 'client_id',
      :exp => ext
    }
  end

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [:iss, :user_id, :aud, :exp] }
    its(:optional_attributes) { should == [:iso29115, :nonce, :issued_to, :secret] }
  end

  describe '#verify!' do
    context 'when valid client_id is given' do
      it { id_token.verify!('client_id').should be_true }

      context 'when expired' do
        let(:ext) { 10.minutes.ago }
        it do
          expect { id_token.verify! 'client_id' }.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
        end
      end
    end

    context 'otherwise' do
      it do
        expect { id_token.verify! 'invalid_client' }.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end
  end

  describe '#to_jwt' do
    subject { id_token.to_jwt }

    context 'when secret is given' do
      let(:attributes) { required_attributes.merge(:secret => 'secret') }
      it { should be_a String }
    end

    context 'otherwise' do
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
    [:iss, :user_id, :aud, :secret].each do |key|
      its(key) { should == attributes[key] }
    end
    its(:exp) { should == attributes[:exp].to_i }
  end
end