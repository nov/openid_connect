require 'spec_helper'

describe Rack::OAuth2::Server::Authorize::Extension::IdTokenAndToken do
  subject { response }
  let(:request)      { Rack::MockRequest.new app }
  let(:response)     { request.get("/?response_type=token%20id_token&client_id=client") }
  let(:redirect_uri) { 'http://client.example.com/callback' }
  let(:bearer_token) { Rack::OAuth2::AccessToken::Bearer.new(:access_token => 'access_token') }
  let :id_token do
    OpenIDConnect::ResponseObject::IdToken.new(
      :iss => 'https://server.example.com',
      :user_id => 'user_id',
      :aud => 'client_id',
      :exp => 1313424327
    )
  end

  context "when id_token is given" do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.access_token = bearer_token
        response.id_token = id_token
        response.private_key = private_key
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should == "#{redirect_uri}#access_token=access_token&id_token=#{id_token.to_jwt(private_key)}&token_type=bearer" }

    context 'when id_token is String' do
      let(:id_token) { 'id_token' }
      its(:location) { should == "#{redirect_uri}#access_token=access_token&id_token=id_token&token_type=bearer" }
    end

    context 'when private_key is missing' do
      let :app do
        Rack::OAuth2::Server::Authorize.new do |request, response|
          response.redirect_uri = redirect_uri
          response.access_token = bearer_token
          response.id_token = id_token
          response.approve!
        end
      end
      it do
        expect { response }.should raise_error AttrRequired::AttrMissing, "'private_key' required."
      end
    end
  end

  context "otherwise" do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.access_token = bearer_token
        response.approve!
      end
    end
    it do
      expect { response }.should raise_error AttrRequired::AttrMissing, "'id_token', 'private_key' required."
    end
  end
end