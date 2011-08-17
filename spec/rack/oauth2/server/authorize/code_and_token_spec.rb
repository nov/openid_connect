require 'spec_helper.rb'
require 'rack/oauth2/server/authorize/extension/code_and_token'

describe Rack::OAuth2::Server::Authorize::Extension::CodeAndToken do
  subject { response }
  let(:request)      { Rack::MockRequest.new app }
  let(:response)     { request.get("/?response_type=code%20token&client_id=client") }
  let(:redirect_uri) { 'http://client.example.com/callback' }
  let(:bearer_token) { Rack::OAuth2::AccessToken::Bearer.new(:access_token => 'access_token') }
  let :id_token do
    OpenIDConnect::ResponseObject::IdToken.new(
      :iss => 'https://server.example.com',
      :user_id => 'user_id',
      :aud => 'client_id',
      :exp => 1313424327,
      :secret => 'secret'
    )
  end

  context "when id_token is given" do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.code = 'code'
        response.access_token = bearer_token
        response.id_token = id_token
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should == "#{redirect_uri}?code=code#access_token=access_token&id_token=#{id_token.to_jwt}&token_type=bearer" }
  end

  context "otherwise" do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.code = 'code'
        response.access_token = bearer_token
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should == "#{redirect_uri}?code=code#access_token=access_token&token_type=bearer" }
  end
end