require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Response do
  let :instance do
    OpenIDConnect::Discovery::Provider::Config::Response.new attributes
  end
  let :attributes do
    {}
  end

  describe '#as_json' do
    subject {
      instance.as_json
    }

    context 'when no attributes given' do
      it do
        should == {:version => '3.0'}
      end
    end

    context 'when user_info_endpoint given' do
      let :attributes do
        {:user_info_endpoint => 'https://server.example.com/user_info'}
      end
      it do
        should include :userinfo_endpoint
      end
      it do
        should_not include :user_info_endpoint
      end
    end

    context 'when user_info_algs_supported given' do
      let :attributes do
        {:user_info_algs_supported => [:HS256, :RS256]}
      end
      it do
        should include :userinfo_algs_supported
      end
      it do
        should_not include :user_info_algs_supported
      end
    end
  end
end