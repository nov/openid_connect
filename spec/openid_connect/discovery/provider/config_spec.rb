require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config do
  let(:provider) { 'https://connect-op.heroku.com' }
  let(:endpoint) { "https://connect-op.heroku.com/.well-known/openid-configuration" }

  describe 'discover!' do
    it 'should setup given attributes' do
      mock_json :get, endpoint, 'discovery/config' do
        config = OpenIDConnect::Discovery::Provider::Config.discover! provider
        config.should be_instance_of OpenIDConnect::Discovery::Provider::Config::Response
        config.version.should == '3.0'
        config.issuer.should == 'https://connect-op.heroku.com'
        config.authorization_endpoint.should == 'https://connect-op.heroku.com/authorizations/new'
        config.token_endpoint.should == 'https://connect-op.heroku.com/access_tokens'
        config.user_info_endpoint.should == 'https://connect-op.heroku.com/user_info'
        config.refresh_session_endpoint.should be_nil
        config.end_session_endpoint.should be_nil
        config.jwk_url.should be_nil
        config.x509_url.should == 'https://connect-op.heroku.com/cert.pem'
        config.registration_endpoint.should == 'https://connect-op.heroku.com/connect/client'
        config.scopes_supported.should == ["openid", "profile", "email", "address"]
        config.response_types_supported.should == ["code", "token", "id_token", "code token", "code id_token", "id_token token"]
        config.acr_values_supported.should be_nil
        config.subject_types_supported.should == ["public", "pairwise"]
        config.claims_supported.should == ["sub", "iss", "name", "email"]
      end
    end

    context 'when SWD::Exception raised' do
      it do
        expect do
          mock_json :get, endpoint, 'errors/unknown', status: [404, 'Not Found'] do
            OpenIDConnect::Discovery::Provider::Config.discover! provider
          end
        end.to raise_error OpenIDConnect::Discovery::DiscoveryFailed
      end
    end
  end

  context 'when OP identifier includes custom port' do
    let(:provider) { 'https://connect-op.heroku.com:8080' }
    let(:endpoint) { "https://connect-op.heroku.com:8080/.well-known/openid-configuration" }

    it 'should construct well-known URI with given port' do
      mock_json :get, endpoint, 'discovery/config' do
        OpenIDConnect::Discovery::Provider::Config.discover! provider
      end
    end
  end

  context 'when OP identifier includes path' do
    let(:provider) { 'https://connect.openid4.us/abop' }
    let(:endpoint) { "https://connect.openid4.us/abop/.well-known/openid-configuration" }

    it 'should construct well-known URI with given port' do
      mock_json :get, endpoint, 'discovery/config' do
        OpenIDConnect::Discovery::Provider::Config.discover! provider
      end
    end
  end
end