require 'spec_helper'

describe OpenIDConnect::Discovery::Principal do
  describe '.parse' do
    {
      'server.example.com' => OpenIDConnect::Discovery::Principal::URI,
      'http://server.example.com' => OpenIDConnect::Discovery::Principal::URI,
      'nov@server.example.com' => OpenIDConnect::Discovery::Principal::Email
    }.each do |input, klass|
      describe input do
        it do
          OpenIDConnect::Discovery::Principal.parse(input).should be_a klass
        end
      end
    end
  end

  describe '#discover!' do
    let(:request) { OpenIDConnect::Discovery::Principal.new.discover! }

    it 'should do SWD discovery' do
      SWD.should_receive(:discover!)
      request
    end

    context 'when port specified' do
      it do
        SWD.should_receive(:discover!).with(
          principal: "https://example.com:8080",
          service: "http://openid.net/specs/connect/1.0/issuer",
          host: "example.com",
          port: 8080,
          cache: {}
        )
        OpenIDConnect::Discovery::Principal.parse('example.com:8080').discover!
      end
    end

    context 'when discovery failed' do
      it do
        SWD.should_receive(:discover!).and_raise(SWD::Exception)
        expect { request }.to raise_error OpenIDConnect::Discovery::DiscoveryFailed
      end
    end
  end
end