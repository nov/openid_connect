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
        :display => 'touch',
        :prompt => 'none',
        :userinfo => {
          :claims => {
            :name => :required,
            :email => :optional
          }
        },
        :id_token => {
          :max_age => 10,
          :claims => {
            :acr => {
              :values => ['2', '3', '4']
            }
          }
        }
      }
    end
    let(:jwtnized) do
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjbGllbnRfaWQiOiJjbGllbnRfaWQiLCJyZXNwb25zZV90eXBlIjoidG9rZW4gaWRfdG9rZW4iLCJyZWRpcmVjdF91cmkiOiJodHRwczovL2NsaWVudC5leGFtcGxlLmNvbSIsInNjb3BlIjoib3BlbmlkIGVtYWlsIiwic3RhdGUiOiJzdGF0ZTEyMzQiLCJub25jZSI6Im5vbmNlMTIzNCIsImRpc3BsYXkiOiJ0b3VjaCIsInByb21wdCI6Im5vbmUiLCJpZF90b2tlbiI6eyJjbGFpbXMiOnsiYWNyIjp7InZhbHVlcyI6WyIyIiwiMyIsIjQiXX19LCJtYXhfYWdlIjoxMH0sInVzZXJpbmZvIjp7ImNsYWltcyI6eyJuYW1lIjp7ImVzc2VudGlhbCI6dHJ1ZX0sImVtYWlsIjp7ImVzc2VudGlhbCI6ZmFsc2V9fX19.MLTDQVPdhAdkJhboM06IRtjHJrvamJ_H2vFGRupXmTA'
    end
    let(:jsonized) do
      {
        :client_id => "client_id",
        :response_type => "token id_token",
        :redirect_uri => "https://client.example.com",
        :scope => "openid email",
        :state => "state1234",
        :nonce => "nonce1234",
        :display => "touch",
        :prompt => "none",
        :id_token => {
          :claims => {
            :acr => {
              :values => ['2', '3', '4']
            }
          },
          :max_age => 10
        },
        :userinfo => {
          :claims => {
            :name => {
              :essential => true
            },
            :email => {
              :essential => false
            }
          }
        }
      }
    end
    it { should be_valid }
    its(:as_json) do
      should == jsonized.with_indifferent_access
    end

    describe '#to_jwt' do
      it do
        request_object.to_jwt('secret', :HS256).should == jwtnized
      end
    end

    describe '.decode' do
      it do
        OpenIDConnect::RequestObject.decode(jwtnized, 'secret').as_json.should == jsonized.with_indifferent_access
      end
    end

    describe '#required?' do
      it do
        request_object.user_info.required?(:name).should be_true
        request_object.user_info.optional?(:name).should be_false
      end
    end

    describe '#optional' do
      it do
        request_object.user_info.required?(:email).should be_false
        request_object.user_info.optional?(:email).should be_true
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
      end.to raise_error OpenIDConnect::ValidationFailed
    end
  end
end