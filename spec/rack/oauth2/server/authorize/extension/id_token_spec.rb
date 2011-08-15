require 'spec_helper'

describe Rack::OAuth2::Server::Authorize::Extension::IdToken do
  let(:request)      { Rack::MockRequest.new app }
  let(:redirect_uri) { 'http://client.example.com/callback' }
  let(:response) do
    request.get("/?response_type=id_token&client_id=client&redirect_uri=#{redirect_uri}")
  end
  let(:id_token) do
    OpenIDConnect::ResponseObject::IdToken.new(
      :iss => 'iss',
      :user_id => 'user_id',
      :aud => 'aud',
      :exp => 10.minutes.from_now,
      :secret => 'secret'
    )
  end

  context "when approved" do
    subject { response }
    
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        response.redirect_uri = redirect_uri
        response.id_token = id_token
        response.approve!
      end
    end
    its(:status)   { should == 302 }
    its(:location) { should == "#{redirect_uri}#id_token=#{id_token.to_jwt}" }
  end

  context 'when denied' do
    let :app do
      Rack::OAuth2::Server::Authorize.new do |request, response|
        request.verify_redirect_uri! redirect_uri
        request.access_denied!
      end
    end
    it 'should redirect with error in fragment' do
      response.status.should == 302
      error_message = {
        :error => :access_denied,
        :error_description => Rack::OAuth2::Server::Authorize::ErrorMethods::DEFAULT_DESCRIPTION[:access_denied]
      }
      response.location.should == "#{redirect_uri}##{error_message.to_query}"
    end
  end
end