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
    its(:optional_attributes) { should == [:acr, :auth_time, :nonce, :user_jwk, :at_hash, :c_hash] }
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
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
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
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when issuer is missing' do
      it do
        expect do
          id_token.verify!(
            :client_id => attributes[:aud]
          )
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when client_id is invalid' do
      it do
        expect do
          id_token.verify!(
            :issuer => attributes[:iss],
            :client_id => 'invalid_client'
          )
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
      end
    end

    context 'when client_id is missing' do
      it do
        expect do
          id_token.verify!(
            :issuer => attributes[:iss]
          )
        end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
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
          end.to raise_error OpenIDConnect::ResponseObject::IdToken::InvalidToken
        end
      end

      context 'when nonce is missing' do
        it do
          expect do
            id_token.verify!(
              :issuer => attributes[:iss],
              :client_id => attributes[:aud]
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
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwidXNlcl9pZCI6IkN5amplQ0trLU9xSS1YcW5GYzduX1pSOG4xaXlLNFlIcXNzNkp1SHlnNkUiLCJhdWQiOiJ0YXBpZC50YXBpZGVudGl0eS5jb20iLCJleHAiOjEzNDkyNDc3ODAsImlhdCI6MTM0OTI0NDE4MCwidXNlcl9qd2siOnsiYWxnIjoiUlNBIiwibW9kIjoibWtra29uTXZuQkxiWkRCZE9lNkM3Ukk3T2xLbjVZazl0eTBSQ0NFa2E5TkVDVVhWRmJqaHdrVjlNeFpSekQ2Q3ZIZDQzUmU5ak5iRFFVQVloNm1peHZtdFFSODlDUFlMeWNvOXIzTlEySXpEZmVPZjlUbFpMUXhpOG9FSVBOeURyN1FoSHlpUTlBRkd6YUhNLW1DU1hCcTRnM0Z4Nko4U1d0MFBRSERoZV9MN3FURTJHbzA4NGRyZUtXMFZSazhBRkxrM2V3cVlvV0RQRXhjcFlNYWNNSUhnaFd1N0pRSG9xX0xId2hmdnk3cnN2MFh1QTR0ai1oNnhvaDhubUR6MjBfdUc5Wm9MZHJ0cE44ZHF1MTdOTDgwTmQ1cVotaHRwVUpSemUzVzdyN3F4Y0dwNEtzQnRhc0NqWlcyWGlyQlZ1eXU2bDNqc3JnTlB2S1NaZ2NpUGdRIiwiZXhwIjoiQVFBQiJ9fQ.gp7Yr3mT3oneZusYMOKB3_777QwJNrQlqiK4x7HpYreuPNbBYHOKo8Jsmqe8gCnrWcOtGHe2Flt1NvN_Yy-7TgVP9L8XyaM9KnWrVEPVCDlf2tIqIAd6MSOfWtiDsA--a7AHfg7o2HcxH3-V3JXS3LQJnzpKBHuaJJIYwj1_8W9sUXwljqNCmnCytrqkmIWocQazoAy5mvmUcpcTWGnSsiibQGk_eQTRjZaiouDDbHWi87IneVQ7UeuurPIYoVK6PWhj0894zcJEyJFWkf2UshgP1grGVO8FC6dvlF5dayt6aUYeGMrTEV8KL6FNYAB9dZKR7xDC4uOjumHTjvQFfA'
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
          'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJpc3MiOiJodHRwczovL3NlbGYtaXNzdWVkLm1lIiwidXNlcl9pZCI6ImludmFsaWRfdXNlcl9pZCIsImF1ZCI6InRhcGlkLnRhcGlkZW50aXR5LmNvbSIsImV4cCI6MTM0OTI0ODgxOCwiaWF0IjoxMzQ5MjQ1MjE4LCJ1c2VyX2p3ayI6eyJhbGciOiJSU0EiLCJtb2QiOiJta2trb25Ndm5CTGJaREJkT2U2QzdSSTdPbEtuNVlrOXR5MFJDQ0VrYTlORUNVWFZGYmpod2tWOU14WlJ6RDZDdkhkNDNSZTlqTmJEUVVBWWg2bWl4dm10UVI4OUNQWUx5Y285cjNOUTJJekRmZU9mOVRsWkxReGk4b0VJUE55RHI3UWhIeWlROUFGR3phSE0tbUNTWEJxNGczRng2SjhTV3QwUFFIRGhlX0w3cVRFMkdvMDg0ZHJlS1cwVlJrOEFGTGszZXdxWW9XRFBFeGNwWU1hY01JSGdoV3U3SlFIb3FfTEh3aGZ2eTdyc3YwWHVBNHRqLWg2eG9oOG5tRHoyMF91Rzlab0xkcnRwTjhkcXUxN05MODBOZDVxWi1odHBVSlJ6ZTNXN3I3cXhjR3A0S3NCdGFzQ2paVzJYaXJCVnV5dTZsM2pzcmdOUHZLU1pnY2lQZ1EiLCJleHAiOiJBUUFCIn19.JTIAhIrjbI5s4-1QelTveJYqFjHz2vMQrkRo---TLtSkSDL4IaBXxXabQm_hgXR_Rh80GV2nAD9BR7PSdH2v4BK-xBzHnVzOIfWGzbB-fySvwEF3AO0cQpy8v95no6R8cbVF6exzVmuC5kLesS3BCjoHjywl-fS1H9fUMhUwDS6OatVg4AC3guz0_9l-cM1JE4Ryko-zLAzAkE8cfvVYyH0UCHAQUcTd2T45JmW4_hzN37ziuTs-xKkQ4fZ6TLURS_Q0sxX2vNIhdP1QQWzBwHwxObFK1O_Zb00KVe7MCB7Uxfisz1FDlFgq0Z0QCrQHuVyFqHqcJQjvPh3ORv0_6g'
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