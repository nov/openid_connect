require 'spec_helper'

describe OpenIDConnect::ResponseObject::IdToken do
  let(:klass)       { OpenIDConnect::ResponseObject::IdToken }
  let(:id_token)    { klass.new attributes }
  let(:attributes)  { required_attributes }
  let(:ext)         { 10.minutes.from_now }
  let(:iat)         { Time.now }
  let :required_attributes do
    {
      iss: 'https://server.example.com',
      sub: 'user_id',
      aud: 'client_id',
      exp: ext,
      iat: iat
    }
  end

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [:iss, :sub, :aud, :exp, :iat] }
    its(:optional_attributes) { should == [:acr, :auth_time, :nonce, :sub_jwk, :at_hash, :c_hash] }
  end

  describe '#verify!' do
    context 'when both issuer, client_id are valid' do
      it do
        id_token.verify!(
          issuer: attributes[:iss],
          client_id: attributes[:aud]
        ).should be_true
      end

      context 'when expired' do
        let(:ext) { 10.minutes.ago }
        it do
          expect do
            id_token.verify!(
              issuer: attributes[:iss],
              client_id: attributes[:aud]
            )
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
        end
      end
    end

    context 'when issuer is invalid' do
      it do
        expect do
          id_token.verify!(
            issuer: 'invalid_issuer',
            client_id: attributes[:aud]
          )
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when issuer is missing' do
      it do
        expect do
          id_token.verify!(
            client_id: attributes[:aud]
          )
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when client_id is invalid' do
      it do
        expect do
          id_token.verify!(
            issuer: attributes[:iss],
            client_id: 'invalid_client'
          )
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when client_id is missing' do
      it do
        expect do
          id_token.verify!(
            issuer: attributes[:iss]
          )
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when nonce is given' do
      let(:attributes)  { required_attributes.merge(nonce: 'nonce') }

      context 'when nonce is valid' do
        it do
          id_token.verify!(
            issuer: attributes[:iss],
            client_id: attributes[:aud],
            nonce: attributes[:nonce]
          ).should be_true
        end
      end

      context 'when nonce is invalid' do
        it do
          expect do
            id_token.verify!(
              issuer: attributes[:iss],
              client_id: attributes[:aud],
              nonce: 'invalid_nonce'
            )
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
        end
      end

      context 'when nonce is missing' do
        it do
          expect do
            id_token.verify!(
              issuer: attributes[:iss],
              client_id: attributes[:aud]
            )
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
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

    context 'when access_token is given' do
      shared_examples_for :id_token_with_at_hash do
        it 'should include at_hash' do
          t = id_token.to_jwt private_key
          jwt = JSON::JWT.decode t, public_key
          jwt.should include :at_hash
          jwt.should_not include :c_hash
          jwt[:at_hash].should == UrlSafeBase64.encode64(
            OpenSSL::Digest::SHA256.digest('access_token')[0, 128 / 8]
          )
        end
      end

      context 'when access_token is a Rack::OAuth2::AccessToken' do
        before { id_token.access_token = Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token') }
        it_should_behave_like :id_token_with_at_hash
      end

      context 'when access_token is a String' do
        before { id_token.access_token = 'access_token' }
        it_should_behave_like :id_token_with_at_hash
      end
    end

    context 'when code is given' do
      before { id_token.code = 'authorization_code' }
      it 'should include at_hash' do
        t = id_token.to_jwt private_key
        jwt = JSON::JWT.decode t, public_key
        jwt.should_not include :at_hash
        jwt.should include :c_hash
        jwt[:c_hash].should == UrlSafeBase64.encode64(
          OpenSSL::Digest::SHA256.digest('authorization_code')[0, 128 / 8]
        )
      end
    end

    context 'when both access_token and code are given' do
      before do
        id_token.access_token = 'access_token'
        id_token.code = 'authorization_code'
      end
      it 'should include at_hash' do
        t = id_token.to_jwt private_key
        jwt = JSON::JWT.decode t, public_key
        jwt.should include :at_hash
        jwt.should include :c_hash
        jwt[:at_hash].should == UrlSafeBase64.encode64(
          OpenSSL::Digest::SHA256.digest('access_token')[0, 128 / 8]
        )
        jwt[:c_hash].should == UrlSafeBase64.encode64(
          OpenSSL::Digest::SHA256.digest('authorization_code')[0, 128 / 8]
        )
      end
    end

    context 'when neither access_token nor code are given' do
      it 'should include at_hash' do
        t = id_token.to_jwt private_key
        jwt = JSON::JWT.decode t, public_key
        jwt.should_not include :at_hash, :c_hash
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
    [:iss, :sub, :aud].each do |key|
      its(key) { should == attributes[key] }
    end
    its(:exp) { should == attributes[:exp].to_i }

    context 'when self-issued' do
      context 'when valid' do
        let(:self_issued) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwic3ViIjoiUFdFYXFfVnlUd1hTSFR4QVlSZHdWTjNMN2s0UnNxOVBwaTZ4WHZ6ZGZWTSIsImF1ZCI6InRhcGlkLnRhcGlkZW50aXR5LmNvbSIsImV4cCI6MTM2MjI3OTkwMCwiaWF0IjoxMzYyMjc2MzAwLCJzdWJfandrIjp7ImFsZyI6IlJTQSIsIm4iOiJ5R21SUm5qSkk2VWhXYUtYcUJxa0RodDVQa0FPdDNqV2Y0SUxIdUlKZHJHR3h1ajBhcDIzLXlxaS16N29jZmF3dnlNbkRfakRpY0JjRTFtVHduZ2ZLRURMdmp5ZWw4U3VhZlZJWTR4ZDVDcG42Nlp4U2pocE1yTWZtMF9palZtdkQ0OTZHZzZSYUR4cHA4OEVqcUlaZUtyZEtqd2lOeTRGZ0dkVnZPQURXWG85R0xLenBOdlc2MGU3MkdrRGFkUVJncEhGNjNVaE9zaVltYmwxRVRMaVhLMGpUdldDdEZVdUlfT2lTN3hIUmU0X3FSaWxRc240cGlHTy1lNzJ2azRpaFlPaldoRXNpcnU2X0JtSC03YWs2Qk9lY3pUYTFVOFZyQzY1ZkRabzRxeG9uRWVoeVpVVnItSmxXMFVvbFVTS1dKOE1OMGRBV1VaeTFBZUxtRzliZlEiLCJlIjoiQVFBQiJ9fQ.obpb9tshLoZG6O32w4nB4I3nBtR_2mscVeNuPWZAGIwq9SqpiNF24KrGrhgbJMzRndafXbOdiiTFjq15BDwoSUrRF2H2EQXm1_lZxhw66JK4get7zEihtmsljGxB03LRlej-ec6baAKJxCBZdJ7SIantjgyt_WbAY27ImeryD7Wi9VKtgEzX2cFbU8u5VwxpisDfosp7fpp0_jdAdk948eJnercM-6t0a3UhLoLaW1RWZSbzXzef9aDuMezsnSrwafjYuF6dzUF7uAEdsYAzMeISch2_Gl4Twbrovmmqj50IKIctkLxQBTI1_v0oU63_a4jLami1cux8XTEfgPEPmg'
        end

        context 'when key == :self_issued' do
          it do
            expect do
              klass.decode self_issued, :self_issued
            end.not_to raise_error
          end
        end

        context 'when key == public_key' do
          it do
            expect do
              klass.decode self_issued, public_key
            end.to raise_error JSON::JWS::VerificationFailed
          end
        end
      end

      context 'when invalid subject' do
        let(:self_issued) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJkZXZpY2VfdG9rZW4iOiI2NjYxNmI2NTJkNjQ2NTc2Njk2MzY1MmQ3NDZmNmI2NTZlIiwiaXNzIjoiaHR0cHM6Ly9zZWxmLWlzc3VlZC5tZSIsInN1YiI6IlBXRWFxX1Z5VHdYU0hUeEFZUmR3Vk4zTDdrNFJzcTlQcGk2eFh2emRmVk1pbnZhbGlkIiwiYXVkIjoidGFwaWQudGFwaWRlbnRpdHkuY29tIiwiZXhwIjoxMzYyMjgwMDQxLCJpYXQiOjEzNjIyNzY0NDEsInN1Yl9qd2siOnsiYWxnIjoiUlNBIiwibiI6InlHbVJSbmpKSTZVaFdhS1hxQnFrRGh0NVBrQU90M2pXZjRJTEh1SUpkckdHeHVqMGFwMjMteXFpLXo3b2NmYXd2eU1uRF9qRGljQmNFMW1Ud25nZktFREx2anllbDhTdWFmVklZNHhkNUNwbjY2WnhTamhwTXJNZm0wX2lqVm12RDQ5NkdnNlJhRHhwcDg4RWpxSVplS3JkS2p3aU55NEZnR2RWdk9BRFdYbzlHTEt6cE52VzYwZTcyR2tEYWRRUmdwSEY2M1VoT3NpWW1ibDFFVExpWEswalR2V0N0RlV1SV9PaVM3eEhSZTRfcVJpbFFzbjRwaUdPLWU3MnZrNGloWU9qV2hFc2lydTZfQm1ILTdhazZCT2VjelRhMVU4VnJDNjVmRFpvNHF4b25FZWh5WlVWci1KbFcwVW9sVVNLV0o4TU4wZEFXVVp5MUFlTG1HOWJmUSIsImUiOiJBUUFCIn19.K8NpQ1r89v9KFcrAU19-qTEtUv94gTJp25xwYwKPttkMOduGMIBn1lCTUsWhUC8NDc0lJrIq-MAa3Eav6wlW9HkX4Gw7vD-fwx6bijm_0LnxLcK2PwMPeeAaeztEOj6WNnUlipZAkOjYhFWG_4gK4sbnoXv80LSV3dHf0mwDEp0vWJ5rba24YfyFb_CoGfeluaHVQiCWTNFa4rh5ohCb1oC4IAZd607KNryLBbjGdyRgIgeIBtph_rx4Jf2tYhBs1_Y32KQMgKHy7QBJHD1hr2HEAu_pCXirwpNFcBCV7K5vUYntYSjdrKfvEzeW0Jxjm1AGgMZr_NsGwNS0bMYoUA'
        end

        it do
          expect do
            klass.decode self_issued, :self_issued
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken, 'Invalid subject'
        end
      end

      context 'when no sub_jwk' do
        let(:self_issued) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJkZXZpY2VfdG9rZW4iOiI2NjYxNmI2NTJkNjQ2NTc2Njk2MzY1MmQ3NDZmNmI2NTZlIiwiaXNzIjoiaHR0cHM6Ly9zZWxmLWlzc3VlZC5tZSIsInN1YiI6IlBXRWFxX1Z5VHdYU0hUeEFZUmR3Vk4zTDdrNFJzcTlQcGk2eFh2emRmVk0iLCJhdWQiOiJ0YXBpZC50YXBpZGVudGl0eS5jb20iLCJleHAiOjEzNjIyODAxNDQsImlhdCI6MTM2MjI3NjU0NH0.HtkguN4xOzJ-yh_kd2JCmG6fgDEiVY5VCgTWUD9l8YOgHjTT7LRZC3b1sNDgkdwBteX3eQIQOVxaYWp4-ftczaIlrznB0jxldqdEdB1Tr591YsiDcyOqmemo1ZYzOKhe_q1l68bdKKeHLc83BzlsJpS659uFDuixvF7G_HIJpCdwckX7x6H3KK73hCLzoYCOVgr_lkFRVVHHAJXzxiUuERLD7JIvg5jCbgmqxArP-jYBdbscHHx8i-UP3WYFBEORBM2rXJuJzGvk4sLhZ4NVGBWyr0DJlE-aWKTyeg-_-4kLPd3d68-k3nLJ82iCwcap-BU_5otSmXufN3_ffq_tTw'
        end

        it do
          expect do
            klass.decode self_issued, :self_issued
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken, 'Missing sub_jwk'
        end
      end
    end
  end

  describe '.self_issued' do
    subject { self_issued }
    let(:sub_jwk) { JSON::JWK.new(public_key) }
    let(:self_issued) do
      klass.self_issued(
        public_key: public_key,
        aud: 'client.example.com',
        exp: 1.week.from_now,
        iat: Time.now
      )
    end

    [:iss, :sub, :aud, :exp, :iat, :sub_jwk].each do |attribute|
      its(attribute) { should be_present }
    end
    its(:iss)      { should == 'https://self-issued.me' }
    its(:sub_jwk) { should == sub_jwk}
    its(:subject)  { should == OpenIDConnect::ResponseObject::IdToken.self_issued_subject(sub_jwk) }
  end

  describe '.self_issued_subject' do
    context 'when RSA key given' do
      let(:jwk) { JSON::JWK.new(public_key) }
      it do
        user_id = klass.self_issued_subject jwk
        user_id.should == UrlSafeBase64.encode64(
          OpenSSL::Digest::SHA256.digest([jwk[:n], jwk[:e]].join)
        )
      end
    end

    context 'when EC key given' do
      let(:jwk) { JSON::JWK.new(ec_public_key) }
      it do
        expect do
          klass.self_issued_subject jwk
        end.to raise_error NotImplementedError
      end
    end

    context 'when unknown algorithm JWK given' do
      let(:jwk) do
        {
          alg: 'unknown'
        }
      end

      it do
        expect do
          klass.self_issued_subject jwk
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end
  end
end