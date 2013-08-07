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

      context 'when aud(ience) is an array of identifiers' do
        let(:client_id) { 'client_id' }
        let(:attributes) { required_attributes.merge(aud: ['some_other_identifier', client_id]) }
        it do
          id_token.verify!(
            issuer: attributes[:iss],
            client_id: client_id
          ).should be_true
        end
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
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwic3ViIjoiOWp1WGpObmFmbUhhdXF5TGNMRXZ2eGkweEZNMlZXZWtEQVhTUTZkMEFfYyIsImF1ZCI6ImNsaWVudC5leGFtcGxlLmNvbSIsImV4cCI6MTM3MzExNTU5OSwiaWF0IjoxMzcyNTEwNzk5LCJzdWJfandrIjp7Imt0eSI6IlJTQSIsImUiOiJBUUFCIiwibiI6InR1V1VKWUlEeTh3SVBnSnhicDNxbkVlaUVyWTk5bTY2N1lqc0JNelYzYUV1WlJobDJhVE81aFpGTXZ0eHljUi1jS3ZiV25Balg2bjgtRlFhb2Z4R1Qyb21NYTZjcTN6S2hjQ2N6dl81UElwVkJEQkpmMDN3YUIzU1h0R2ZtVDdBMklYUHdSSER4Tjllc0s1dWxzT0MtZl9IOXM4N3Z0U0RYVUhLZDVxS0JaNzhfc0I4eG10UFk0OGVmRVRXNnVDZHBnSy11U1hsYVJKbnN3YXRfdlIyRHJCWjZiOUJfQ0dYWHYxS1JRX1dDUmxoR2RNX294dFNMWHZGai00MlNFSnU5RHB3UzhjRUhKRTFHeU8xSmM2V1dfSTJZMXR5ZUs1Zm1RREpHZklpcUJvWkdBRFg1RUpjYm1aMmtWU2gxaXB0c2dZRUk0c2U0MW15LTdaUGZlZkQ4USJ9fQ.Gy31NnvCUSnS-cZuC4kQqR-DHcvZ0b8y7sNnp-2oCpXoHydGkVoVLsGXesUz6KB7RSB2cjoBySz0_k4eI_Trg7pR94zHCPf4U76mnCujGj7x09O3THlwiyYE3-V2ejhfAEhAXkzQNFu57HbWtvHVGP8SHnNs5NUY2YqJvchQ2uCrWYU4OyHdEnMQXbAdZcj2ltNIHREXtZTOxZhJ5fYUIbynBC27lxETI0LTHfHAzSwzKuFpM0zE99Uhrt7v17Us8gAGlUZIC-A3x2Och_8ryBCJaugROagSv3FoS-LvzaciEu5VLbi3EB9sFP4et_12ZSjFWNEAw5VeSBzF1l0kBQ'
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
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwic3ViIjoiUFdFYXFfVnlUd1hTSFR4QVlSZHdWTjNMN2s0UnNxOVBwaTZ4WHZ6ZGZWTSIsImF1ZCI6InRhcGlkLnRhcGlkZW50aXR5LmNvbSIsImV4cCI6MTM2MjI3OTkwMCwiaWF0IjoxMzYyMjc2MzAwLCJzdWJfandrIjp7Imt0eSI6IlJTQSIsImUiOiJBUUFCIiwibiI6IjRGTWl5M08zbFlOd2RzeC15aXVjemRsek81eU11d1p4WFlzSDgydmM0RkM0QXgyMGpNVV94emJHSUhWVUtFQ0pndFp3clBlajhRSWUtZFZFYXQtaGxjNTB5TXluM0h3cmtJVjVZOTdET1E2Sks4azk2QTFqVWxPLW5sRjl4ZUx2VDlwYTJXRTZtYm1KOG5EQW5mR0d6bmRNd3VKNzVLZDI2YmZHY21wcm5qUUJLTkVrakdJbW9MMEhFODFUcjROeC1tN1lsYkRGaVFNRDVpYjhCY3N4S0tvMTZTeG5tSi1EeUY2c094Y2JtV1ZrdkZBa3FKWFBnVFVoNXVYT3YwYk9nN0I2d2RHdUMtWnpJUl8tdUx3YlcxN2V4NGx3ZTFPb0ppdFJ3SFczYlo3NEc3RkdoSmhfTUp4YzB3WXBkbW5uNVpjRFFOWl9sWVRvMHYzaU1PUWk3USJ9fQ.DZKaSne22DjKFSpSUphsTeCMkcMWDexQCm8BPb1nI1PzQYsEAOfwumDajt85UA0x28y2zuOevMj29VpwTzbpRDkduv2NWAI4MHw8DYEsIN__-QGANmdU1sKmthET2iFmeFySwWomLqFvYIaNmVYVLkD53Zqfct5qH3Wznd_hrK8T1d6Cxg-gyZlAeqEu2V8EL2yuz8Gdaeze4b78l5Ux-B_5FQhZ3UkXbL1B2gzKJQVKAQdFJb9zUfzmCeIiUmeM9mw_VU64tAvFDRiTKS1P6b62Gxuyx1DhMLFg2evDaTJERJOta9ywtPfdcLH3qcIiUBffP2-FnAz44bOlKzJorQ'
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
    its(:iss)     { should == 'https://self-issued.me' }
    its(:sub_jwk) { should == sub_jwk}
    its(:subject) { should == OpenIDConnect::ResponseObject::IdToken.self_issued_subject(sub_jwk) }
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