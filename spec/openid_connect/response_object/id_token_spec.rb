require 'spec_helper'

describe OpenIDConnect::ResponseObject::IdToken do
  let(:klass)       { OpenIDConnect::ResponseObject::IdToken }
  let(:id_token)    { klass.new attributes }
  let(:attributes)  { required_attributes }
  let(:ext)         { 10.minutes.from_now }
  let(:iat)         { Time.now }
  let :required_attributes do
    {
      :iss => 'https://server.example.com',
      :user_id => 'user_id',
      :aud => 'client_id',
      :exp => ext,
      :iat => iat
    }
  end

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [:iss, :user_id, :aud, :exp, :iat] }
    its(:optional_attributes) { should == [:acr, :auth_time, :nonce, :at_hash, :c_hash] }
  end

  describe '#verify!' do
    context 'when both issuer, client_id are valid' do
      it do
        id_token.verify!(
          :issuer => attributes[:iss],
          :client_id => attributes[:aud]
        ).should be_true
      end

      context 'when expired' do
        let(:ext) { 10.minutes.ago }
        it do
          expect do
            id_token.verify!(
              :issuer => attributes[:iss],
              :client_id => attributes[:aud]
            )
          end.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
        end
      end
    end

    context 'when issuer is invalid' do
      it do
        expect do
          id_token.verify!(
            :issuer => 'invalid_issuer',
            :client_id => attributes[:aud]
          )
        end.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when issuer is missing' do
      it do
        expect do
          id_token.verify!(
            :client_id => attributes[:aud]
          )
        end.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when client_id is invalid' do
      it do
        expect do
          id_token.verify!(
            :issuer => attributes[:iss],
            :client_id => 'invalid_client'
          )
        end.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when client_id is missing' do
      it do
        expect do
          id_token.verify!(
            :issuer => attributes[:iss]
          )
        end.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when nonce is given' do
      let(:attributes)  { required_attributes.merge(:nonce => 'nonce') }

      context 'when nonce is valid' do
        it do
          id_token.verify!(
            :issuer => attributes[:iss],
            :client_id => attributes[:aud],
            :nonce => attributes[:nonce]
          ).should be_true
        end
      end

      context 'when nonce is invalid' do
        it do
          expect do
            id_token.verify!(
              :issuer => attributes[:iss],
              :client_id => attributes[:aud],
              :nonce => 'invalid_nonce'
            )
          end.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
        end
      end

      context 'when nonce is missing' do
        it do
          expect do
            id_token.verify!(
              :issuer => attributes[:iss],
              :client_id => attributes[:aud]
            )
          end.should raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
        end
      end
    end
  end

  describe '#to_jwt' do
    subject { id_token.to_jwt private_key }
    it { should be_a String }

    context 'when block given' do
      it 'should allow add additional headers' do
        t = id_token.to_jwt private_key do |t|
          t.header[:x5u] = "http://server.example.com/x5u"
        end
        h = UrlSafeBase64.decode64 t.split('.').first
        h.should include 'x5u'
      end
    end
  end

  describe '#as_json' do
    subject { id_token.as_json }
    let(:attributes) { required_attributes }
    it do
      hash = required_attributes
      hash[:exp] = required_attributes[:exp].to_i
      should == hash
    end
  end

  describe '.decode' do
    subject { klass.decode id_token.to_jwt(private_key), public_key }
    let(:attributes) { required_attributes }
    it { should be_a klass }
    [:iss, :user_id, :aud].each do |key|
      its(key) { should == attributes[key] }
    end
    its(:exp) { should == attributes[:exp].to_i }
  end
end