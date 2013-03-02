require 'spec_helper'

describe OpenIDConnect do
  after { OpenIDConnect.debugging = false }

  its(:logger) { should be_a Logger }
  its(:debugging?) { should be_false }

  describe '.debug!' do
    before { OpenIDConnect.debug! }
    its(:debugging?) { should be_true }
  end

  describe '.debug' do
    it 'should enable debugging within given block' do
      OpenIDConnect.debug do
        SWD.debugging?.should be_true
        WebFinger.debugging?.should be_true
        Rack::OAuth2.debugging?.should be_true
        OpenIDConnect.debugging?.should be_true
      end
      SWD.debugging?.should be_false
      Rack::OAuth2.debugging?.should be_false
      OpenIDConnect.debugging?.should be_false
    end

    it 'should not force disable debugging' do
      SWD.debug!
      WebFinger.debug!
      Rack::OAuth2.debug!
      OpenIDConnect.debug!
      OpenIDConnect.debug do
        SWD.debugging?.should be_true
        WebFinger.debugging?.should be_true
        Rack::OAuth2.debugging?.should be_true
        OpenIDConnect.debugging?.should be_true
      end
      SWD.debugging?.should be_true
      WebFinger.debugging?.should be_true
      Rack::OAuth2.debugging?.should be_true
      OpenIDConnect.debugging?.should be_true
    end
  end

  describe '.http_client' do
    context 'with http_config' do
      before do
        OpenIDConnect.http_config do |config|
          config.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end
      it 'should configure OpenIDConnect, SWD and Rack::OAuth2\'s http_client' do
        [OpenIDConnect, SWD, WebFinger, Rack::OAuth2].each do |klass|
          klass.http_client.ssl_config.verify_mode.should == OpenSSL::SSL::VERIFY_NONE
        end
      end
    end
  end
end