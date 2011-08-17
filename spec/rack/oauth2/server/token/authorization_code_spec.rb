require 'spec_helper.rb'

describe Rack::OAuth2::Server::Token::AuthorizationCode do
  subject { response }
  let(:request) { Rack::MockRequest.new app }
  let :response do
    request.post('/', :params => {
      :grant_type => 'authorization_code',
      :client_id => 'client_id',
      :code => 'authorization_code',
      :redirect_uri => 'http://client.example.com/callback'
    })
  end
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
      Rack::OAuth2::Server::Token.new do |request, response|
        response.access_token = Rack::OAuth2::AccessToken::Bearer.new(:access_token => 'access_token')
        response.id_token = id_token
      end
    end
    its(:status) { should == 200 }
    its(:body)   { should include "\"id_token\":\"#{id_token.to_jwt}\"" }
  end

  context "otherwise" do
    let :app do
      Rack::OAuth2::Server::Token.new do |request, response|
        response.access_token = Rack::OAuth2::AccessToken::Bearer.new(:access_token => 'access_token')
      end
    end
    its(:status) { should == 200 }
    its(:body)   { should_not include "id_token" }
  end
end