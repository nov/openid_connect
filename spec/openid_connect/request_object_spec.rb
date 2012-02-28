require 'spec_helper'

describe OpenIDConnect::RequestObject do
  subject { request_object }
  let(:request_object) { OpenIDConnect::RequestObject.new attributes }

  context 'with all attributes' do
    let(:attributes) do
      {
        :client_id => 'client_id',
        :response_type => 'token id_token',
        :redirect_uri => 'https://client.example.com',
        :scope => 'openid email',
        :state => 'state1234',
        :nonce => 'nonce1234',
        :display => :touch,
        :prompt => :none,
        :userinfo => {
          :claims => {
            :name => :required
          }
        },
        :id_token => {
          :max_age => 10,
          :claims => {
            :acr => {
              :values => [2, 3, 4]
            }
          }
        }
      }
    end
    let(:jwtnized) do
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjbGllbnRfaWQiOiJjbGllbnRfaWQiLCJyZXNwb25zZV90eXBlIjoidG9rZW4gaWRfdG9rZW4iLCJyZWRpcmVjdF91cmkiOiJodHRwczovL2NsaWVudC5leGFtcGxlLmNvbSIsInNjb3BlIjoib3BlbmlkIGVtYWlsIiwic3RhdGUiOiJzdGF0ZTEyMzQiLCJub25jZSI6Im5vbmNlMTIzNCIsImRpc3BsYXkiOiJ0b3VjaCIsInByb21wdCI6Im5vbmUiLCJpZF90b2tlbiI6eyJjbGFpbXMiOnsiYWNyIjp7InZhbHVlcyI6WzIsMyw0XX19LCJtYXhfYWdlIjoxMH0sInVzZXJpbmZvIjp7ImNsYWltcyI6eyJuYW1lIjpudWxsfX19.8tgLupcioh7eTBmX21rqHmk9aOP81PAp6L1nwqEPME8'
    end
    let(:jsonized) do
      {
        :client_id => "client_id",
        :response_type => "token id_token",
        :redirect_uri => "https://client.example.com",
        :scope => "openid email",
        :state => "state1234",
        :nonce => "nonce1234",
        :display => :touch,
        :prompt => :none,
        :id_token => {
          :claims => {
            :acr => {
              :values => [2, 3, 4]
            }
          },
          :max_age => 10
        },
        :userinfo => {
          :claims => {
            :name => nil
          }
        }
      }
    end
    it { should be_valid }
    its(:as_json) do
      should == jsonized
    end
    
    describe '#to_jwt' do
      it do
        request_object.to_jwt('secret', :HS256).should == jwtnized
      end
    end

    describe '.decode' do
      it do
        OpenIDConnect::RequestObject.decode(jwtnized, 'secret').to_json.should == jsonized.to_json
      end
    end
  end

  context 'with no attributes' do
    let(:attributes) do
      {}
    end
    it { should_not be_valid }
    it do
      expect do
        request_object.as_json
      end.should raise_error OpenIDConnect::ValidationFailed
    end
  end
end