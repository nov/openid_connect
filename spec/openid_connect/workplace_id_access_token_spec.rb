require 'spec_helper'

describe OpenIDConnect::WorkplaceIdAccessToken do
  subject { access_token }
  let :client do
    OpenIDConnect::Client.new(
      identifier:'client_id',
      host: 'server.example.com'
    )
  end
  let :access_token do
    OpenIDConnect::WorkplaceIdAccessToken.new(
      id_token: 'id_token',
      client: client
    )
  end

  context 'when id_token is given' do
    subject { access_token }
    let :access_token do
      OpenIDConnect::WorkplaceIdAccessToken.new(
        'id_token' => 'id_token',
        'client' => client
      )
    end

    context 'when JWT string' do
      its(:id_token) { should == 'id_token' }
    end
  end

  describe '#userinfo!' do
    it do
      userinfo = access_token.userinfo!
      userinfo.should be_instance_of OpenIDConnect::HttpError
    end
  end
end