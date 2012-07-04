require 'spec_helper.rb'

describe Rack::OAuth2::Server::Resource::ErrorWithConnectExt do
  let(:env)     { Rack::MockRequest.env_for("/authorize?client_id=client_id") }
  let(:request) { Rack::OAuth2::Server::Resource::Request.new env }

  describe 'invalid_schema!' do
    it do
      expect { request.invalid_schema! }.should raise_error Rack::OAuth2::Server::Resource::BadRequest
    end
  end
end