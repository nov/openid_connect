require 'spec_helper'

describe OpenIDConnect::Client do
  subject { client }
  let(:client) { OpenIDConnect::Client.new attributes }
  let(:attributes) { required_attributes }
  let :required_attributes do
    {
      :identifier => 'client_id'
    }
  end

  describe 'endpoints' do
    context 'when host info is given' do
      let :attributes do
        required_attributes.merge(
          :host => 'server.example.com'
        )
      end
      its(:authorization_uri) { should include 'https://server.example.com/oauth2/authorize' }
      its(:authorization_uri) { should include 'scope=openid' }
      its(:introspection_uri) { should == 'https://server.example.com/id_tokens' }
      its(:user_info_uri)     { should == 'https://server.example.com/user_info' }
    end

    context 'otherwise' do
      [:authorization_uri, :introspection_uri, :user_info_uri].each do |endpoint|
        describe endpoint do
          it do
            expect { client.send endpoint }.should raise_error 'No Host Info'
          end
        end
      end
    end
  end

  describe '#authorization_uri' do
    describe 'scope' do
      subject do
        query = URI.parse(client.authorization_uri :scope => scope).query
        Rack::Utils.parse_query(query).with_indifferent_access[:scope]
      end
      let(:scope) { nil }
      let :attributes do
        required_attributes.merge(
          :host => 'server.example.com'
        )
      end

      context 'when scope is given' do
        context 'when openid scope is included' do
          let(:scope) { [:openid, :email] }
          it { should == 'openid email' }
        end

        context 'otherwise' do
          let(:scope) { :email }
          it { should == 'email openid' }
        end
      end

      context 'otherwise' do
        it { should == 'openid' }
      end
    end
  end

  describe '#access_token!' do
    let :attributes do
      required_attributes.merge(
        :secret => 'client_secret',
        :token_endpoint => 'http://server.example.com/access_tokens'
      )
    end
    let :protocol_params do
      {
        :client_id => 'client_id',
        :client_secret => 'client_secret',
        :grant_type => 'authorization_code',
        :code => 'code'
      }
    end
    let :access_token do
      client.authorization_code = 'code'
      client.access_token!
    end

    context 'when bearer token is returned' do
      it 'should return OpenIDConnect::AccessToken' do
        mock_json :post, client.token_endpoint, 'access_token/bearer', :params => protocol_params do
          access_token.should be_a OpenIDConnect::AccessToken
        end
      end

      context 'when id_token is returned' do
        it 'should include id_token' do
          mock_json :post, client.token_endpoint, 'access_token/bearer_with_id_token', :params => protocol_params do
            access_token.id_token.should == 'id_token'
          end
        end
      end
    end

    context 'otherwise' do
      it 'should raise Unexpected Token Type exception' do
        mock_json :post, client.token_endpoint, 'access_token/mac', :params => protocol_params do
          expect { access_token }.should raise_error OpenIDConnect::Exception, 'Unexpected Token Type: mac'
        end
      end
    end
  end
end