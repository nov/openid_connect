require 'spec_helper'

describe OpenIDConnect::Discovery::Provider do
  let(:provider) { 'https://server.example.com' }
  let(:discover) { OpenIDConnect::Discovery::Provider.discover! identifier }
  let(:endpoint) { "https://#{host}/.well-known/simple-web-discovery" }
  let(:query) do
    {
      :service => OpenIDConnect::Discovery::Provider::SERVICE_URI,
      :principal => principal
    }
  end

  shared_examples_for :discover_provider do
    it "should succeed" do
      mock_json :get, endpoint, 'discovery/swd', :params => query do
        res = discover
        res.should be_a SWD::Response
        res.location.should == provider
      end
    end
  end

  describe '#discover!' do

    context 'when URI is given' do
      let(:principal) { identifier }

      context 'when scheme included' do
        let(:host) { URI.parse(identifier).host }

        context 'when HTTPS' do
          let(:identifier) { 'https://server.example.com' }
          it_behaves_like :discover_provider
        end

        context 'otherwise' do
          let(:identifier) { 'http://server.example.com' }
          it_behaves_like :discover_provider
          it 'should access to https://**' do
            endpoint.should match /^https:\/\//
          end
        end
      end

      context 'when only host is given' do
        let(:identifier) { 'server.example.com' }
        let(:host)       { identifier }
        let(:principal)  { "https://#{identifier}" }
        it_behaves_like :discover_provider
      end
    end

    context 'when Email is given' do
      let(:identifier) { "nov@#{host}" }
      let(:host)       { 'server.example.com' }
      let(:principal)  { identifier }
      it_behaves_like :discover_provider
    end

  end
end