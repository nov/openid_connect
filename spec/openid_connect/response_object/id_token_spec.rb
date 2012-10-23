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
      user_id: 'user_id',
      aud: 'client_id',
      exp: ext,
      iat: iat
    }
  end

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [:iss, :user_id, :aud, :exp, :iat] }
    its(:optional_attributes) { should == [:acr, :auth_time, :nonce, :user_jwk, :at_hash, :c_hash] }
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
    [:iss, :user_id, :aud].each do |key|
      its(key) { should == attributes[key] }
    end
    its(:exp) { should == attributes[:exp].to_i }

    context 'when self-issued' do
      context 'when valid' do
        let(:self_issued) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwidXNlcl9pZCI6ImhXSnphYnYweEY2Q08ycmJMb0hhMGlHamVSOWFCTFFUaDBYbkhPR2xYNk0iLCJhdWQiOiJiYWZkOGI3ODdhMDQyOWRiZDBiNmY5ZTE4Mzk3OThjNDFkNGQxOTJhYWYzMTFhZGY0MGRhMmM0ZDQxNGU1OGZkIiwiZXhwIjoxMzUwMzI1OTg3LCJpYXQiOjEzNTAzMjIzODcsInVzZXJfandrIjp7ImFsZyI6IlJTQSIsIm1vZCI6InB4WmNhN1hrajFZalR5dlNOLThNaFlPU1RuMGluTF9fYTNEZWg5dlZoS1dLaG9FWFlENHNpR0RGSTVIaFBrLWp1SU5HWk9IX0FDc1hIOFNoRWlqMXZzSHpmSTRKeDdxOFREc2ZmZzNNT0d0aWFqZjFJZ250SjR6ck9OeHYzOU5QdEJ6dml2Q3ZLa2MzSXJsSS00X216ajg4R2JER1B6NnBLRDRhcmNndFg0VEdCYmdPTUZaa09nRWk5bml0VzhDbV9zMHFlQ3FtMWxMS0l0QXFaYWJYa2d2cGN5Qjdjb1ZNNnZkLWNYVXY3TDg5MmgxVm9uenVRZTNfUF9MTy1HNV9FNGRVY1B0NmJDbUo4QjNPd3A0bmdQQmpKSHdiTHlqT0F5VjZ2aXRPeUdjZnVPRVE3dkZQdGRNc0hLX29TZnZqU2s2My1xdjRiRDFKaml3OVBBU1NRUSIsInhwbyI6IkFRQUIifX0.YbcccWDBwgtvIMravxJQi3Wmq4fH2BR1Y7qBpt39QH3MKpaHbfpRfkpU2H9SPS4tJZzHnz-iDPVghrWTyLeBZHZigES8oMPM28NxswSKNuDYid-G4d0DAN1A2LdMBPqZd-pAbjop6o8FU1V11WTUoWcQR8OJg912q6I_zZIvCUnlGc9Jx0hnDioW7j2DAYfwji9sLtRybE85-KC8dHwRjrgl5doh3J72QQAi9Vn-KkHz3d5nTFngE-7MFa2ndLiR_7qcqWlCLjEOEDFyj2GtLv-aDYRocOt7TDJmxzDnzRPuNoTuiPiHmSM599kbiKBR_734wqUBunbRQCIOhOrp9Q'
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

      context 'when invalid user_id' do
        let(:self_issued) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwidXNlcl9pZCI6ImludmFsaWQiLCJhdWQiOiJ0YXBpZC50YXBpZGVudGl0eS5jb20iLCJleHAiOjEzNTAzMjYyNjEsImlhdCI6MTM1MDMyMjY2MSwidXNlcl9qd2siOnsiYWxnIjoiUlNBIiwibW9kIjoidnVLay1YdDR3bXF3Wl9HR2FXMTNVeV9RUExobThJVUM1SGpsZlJTZEpXRGY4bnRWV1p2bVRZcjEyd2tfUU1XN3RkQ25Eb0d2dnd0VVczajhIaTlEOG5aNW84c0FhSUxmbm1MSE9sdHNVT01IWTRlOWZtVzQ5eWJUS25sbFRkTGlJMy13NWJtZC1VTVE4WnBSQ2dhN0Z5WERMR2tpeXNrSTNtdjAxcUVfOURMc0dEVTFjWHBaM19TY05MY1RuN0hYSHRCcnVVOHhhOHZkUGxncEdXQjFTaTIxRWhubnNOQnZmUmkzUW9UcFlkbnFqTGk4NzQtWDd4anJWUDNzRURoRnNvdzdNR0s2WVF3X2JsNzAxdGJIU3F1SG5aWDZ0ZklQaFNMYVNWbXdGVzNTem9GdDBWNGxpbzlPOHhqNWlpQnBNV0cwcDd4MTJpYno1bEktaGYzcTJ3IiwieHBvIjoiQVFBQiJ9fQ.p_Zh-nLBVaDQXTvDe3YCDQsA8QKepMfEtEzmBBQEmnFEmLSDAcsTnAbkTNlRZ-BQ-CuEF_NFJ2KK0B8s4GEfb5IO3afBHi5nxk269d1BLypuLRG1oI5GWoO5kPPjcjdZHUHXv56w_c8KeOtRazCKhcVwvErs8vXi1hlAfln5cGMhJ-jlBztk1ZUHefvdCecGyqxzCVnjowA1MsMDhdchDX3njza6qxL8IkPZ04u57KnLsfYTh84jZ4vv0_5bdCs_-fSWXDMvyhDN69_YRT6QqX312421IJqDsIjUWk6VpCFi6Yti7iRZ8qixd5UVyxLHMkomY8okVG04oMHs9lMzDQ'
        end

        it do
          expect do
            klass.decode self_issued, :self_issued
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken, 'Invalid user_id'
        end
      end

      context 'when no user_jwk' do
        let(:self_issued) do
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwidXNlcl9pZCI6IkN5amplQ0trLU9xSS1YcW5GYzduX1pSOG4xaXlLNFlIcXNzNkp1SHlnNkUiLCJhdWQiOiJ0YXBpZC50YXBpZGVudGl0eS5jb20iLCJleHAiOjEzNDkyNDg5NjAsImlhdCI6MTM0OTI0NTM2MH0.SyXFCTAAB0l29qxnfUxj5G217cQqVhCiPlQDCq_ZZmtZyGqM4eLI-5D2MPZTc905i10sbwKHTeKqwjhYki2pVOuU5n-N9duTlO64kimg8hAnwEJKsil9jvRPb5hCnc-5vRyXaRV3N1zYFurCEZFmVvXCg4ccKbA_viyuhIYtiMQPHOGY-ELFokfwsbEv11hi9d0kt89pfBMlDyEIZiEDYT0fEl-w7e8tPEk99rCzD_jkitTtdXv18_UsgeM2pDaO9G7_8wQYAX4ldHZjXSihKp2DuTY7edZpP4arYIFHPibtPVcKEnpmK-25mk9Ujo6k7N5kqz9SX6isktbE9-3W4Q'
        end

        it do
          expect do
            klass.decode self_issued, :self_issued
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken, 'Missing user_jwk'
        end
      end
    end
  end
end