require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Resource do
  let(:resource) do
    uri = URI.parse 'http://server.example.com'
#    SHA256 = 'e1335e881cf563c3fe4fb26a39fb410012e940a52cd9fa456fbe37b48d213ba2'
    OpenIDConnect::Discovery::Provider::Config::Resource.new uri
  end

  describe '#endpoint' do
    context 'when invalid host' do
      before do
        resource.host = 'hoge*hoge'
      end

      it do
        expect { resource.endpoint }.to raise_error SWD::Exception
      end
    end

#   since the cache_key is private can't test it
#    context 'when validate sha256 on host' do
#      it do
#        resource.cache_key.should == "swd:resource:opneid-conf:#{SHA256}"
#      end
#    end
  end
end