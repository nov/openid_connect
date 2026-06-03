require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Resource do
  let(:resource) do
    uri = URI.parse 'http://server.example.com'
    OpenIDConnect::Discovery::Provider::Config::Resource.new uri
  end

  describe '#endpoint' do
    context 'when invalid host' do
      before do
        resource.host = 'invalid:host'
      end

      it do
        expect { resource.endpoint }.to raise_error SWD::Exception
      end
    end
  end

  describe 'discovery_path' do
    context 'with default discovery_path' do
      it 'should use .well-known/openid-configuration' do
        uri = URI.parse 'https://example.com'
        resource = OpenIDConnect::Discovery::Provider::Config::Resource.new uri
        resource.endpoint.to_s.should == 'https://example.com/.well-known/openid-configuration'
      end
    end

    context 'with custom discovery_path' do
      it 'should use the provided path' do
        uri = URI.parse 'https://example.com'
        resource = OpenIDConnect::Discovery::Provider::Config::Resource.new uri, discovery_path: '.well-known/wallet-openid-configuration'
        resource.endpoint.to_s.should == 'https://example.com/.well-known/wallet-openid-configuration'
      end
    end

    context 'with custom discovery_path and URI path' do
      it 'should join URI path and discovery_path' do
        uri = URI.parse 'https://example.com/auth/realms/my-realm'
        resource = OpenIDConnect::Discovery::Provider::Config::Resource.new uri, discovery_path: '.well-known/wallet-openid-configuration'
        resource.endpoint.to_s.should == 'https://example.com/auth/realms/my-realm/.well-known/wallet-openid-configuration'
      end
    end
  end
end