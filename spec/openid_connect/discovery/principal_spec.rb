require 'spec_helper'

describe OpenIDConnect::Discovery::Principal do
  describe '.parse' do
    {
      'server.example.com' => OpenIDConnect::Discovery::Principal::URI,
      'http://server.example.com' => OpenIDConnect::Discovery::Principal::URI,
      'nov@server.example.com' => OpenIDConnect::Discovery::Principal::Email,
      '=nov' => OpenIDConnect::Discovery::Principal::XRI,
      '@nov' => OpenIDConnect::Discovery::Principal::XRI
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

    context 'when discovery failed' do
      it do
        SWD.should_receive(:discover!).and_raise(SWD::Exception)
        expect { request }.should raise_error OpenIDConnect::Discovery::DiscoveryFailed
      end
    end
  end
end