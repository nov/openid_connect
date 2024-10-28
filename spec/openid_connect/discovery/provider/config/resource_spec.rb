require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Resource do
  describe '#endpoint' do
    context 'when invalid host' do
      let(:resource) do
        uri = URI.parse 'http://server.example.com'
        OpenIDConnect::Discovery::Provider::Config::Resource.new uri
      end
      
      before do
        resource.host = 'hoge*hoge'
      end

      it do
        expect { resource.endpoint }.to raise_error SWD::Exception
      end
    end

    context 'when HTTP URI' do
      let(:resource) do
        uri = URI.parse 'http://server.example.com'
        OpenIDConnect::Discovery::Provider::Config::Resource.new uri
      end

      it 'should preserve HTTP scheme' do
        expect(resource.endpoint.to_s).to eq 'http://server.example.com/.well-known/openid-configuration'
      end
    end

    context 'when HTTPS URI' do
      let(:resource) do
        uri = URI.parse 'https://server.example.com'
        OpenIDConnect::Discovery::Provider::Config::Resource.new uri
      end

      it 'should preserve HTTPS scheme' do
        expect(resource.endpoint.to_s).to eq 'https://server.example.com/.well-known/openid-configuration'
      end
    end
  end
end
