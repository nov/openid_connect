require 'spec_helper'

describe OpenIDConnect::AccessToken do
  subject { token }
  let :client do
    OpenIDConnect::Client.new(
      :identifier => 'client_id',
      :host => 'server.example.com'
    )
  end
  let :token do
    OpenIDConnect::AccessToken.new(
      :access_token => 'access_token',
      :client => client
    )
  end
  its(:token_type) { should == :bearer }

  describe '#user_info!' do
    it 'should return OpenIDConnect::ResponseObject::UserInfo::OpenID' do
      mock_json :get, client.user_info_uri, 'user_info/openid', :HTTP_AUTHORIZATION => 'Bearer access_token' do
        token.user_info!.should be_a OpenIDConnect::ResponseObject::UserInfo::OpenID
      end
    end

    describe 'error handling' do
      context 'when bad_request' do
        it 'should raise OpenIDConnect::Forbidden' do
          mock_json :get, client.user_info_uri, 'errors/invalid_request', :HTTP_AUTHORIZATION => 'Bearer access_token', :status => 400 do
            expect { token.user_info! }.should raise_error OpenIDConnect::BadRequest
          end
        end
      end

      context 'when unauthorized' do
        it 'should raise OpenIDConnect::Unauthorized' do
          mock_json :get, client.user_info_uri, 'errors/invalid_access_token', :HTTP_AUTHORIZATION => 'Bearer access_token', :status => 401 do
            expect { token.user_info! }.should raise_error OpenIDConnect::Unauthorized
          end
        end
      end

      context 'when forbidden' do
        it 'should raise OpenIDConnect::Forbidden' do
          mock_json :get, client.user_info_uri, 'errors/insufficient_scope', :HTTP_AUTHORIZATION => 'Bearer access_token', :status => 403 do
            expect { token.user_info! }.should raise_error OpenIDConnect::Forbidden
          end
        end
      end

      context 'when unknown' do
        it 'should raise OpenIDConnect::HttpError' do
          mock_json :get, client.user_info_uri, 'errors/unknown', :HTTP_AUTHORIZATION => 'Bearer access_token', :status => 500 do
            expect { token.user_info! }.should raise_error OpenIDConnect::HttpError
          end
        end
      end
    end
  end

  describe '#id_token!' do
    it 'should return OpenIDConnect::ResponseObject::IdToken' do
      mock_json :get, client.introspection_uri, 'id_token', :HTTP_AUTHORIZATION => 'Bearer access_token' do
        token.id_token!.should be_a OpenIDConnect::ResponseObject::IdToken
      end
    end
  end
end