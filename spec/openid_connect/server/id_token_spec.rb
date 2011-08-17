require 'spec_helper.rb'

describe OpenIDConnect::Server::IdToken do
  let(:request) { Rack::MockRequest.new app }
  let :app do
    OpenIDConnect::Server::IdToken.new do |req, res|
      res.id_token = id_token
    end
  end
  let :env do
    Rack::MockRequest.env_for(
      '/id_token',
      :params => params
    )
  end
  let :params do
    {:id_token => id_token.to_jwt}
  end
  let :id_token do
    OpenIDConnect::ResponseObject::IdToken.new(
      :iss => 'https://server.example.com',
      :user_id => 'user_id',
      :aud => 'client_id',
      :exp => 1313424327,
      :secret => 'secret'
    )
  end
  subject { request.post('/id_token', :params => params) }

  context 'when valid id_token is given' do
    it 'should extract it' do
      status, header, response = app.call(env)
      status.should == 200
      response.body.first.should == id_token.to_json
    end
  end

  context 'otherwise' do
    context 'when missing' do
      let :params do
        {}
      end
      it do
        status, header, response = app.call(env)
        status.should == 400
        response.body.first.should include '"error":"invalid_request"'
      end
    end

    context 'when rejected by authenticator' do
      let :app do
        OpenIDConnect::Server::IdToken.new do |req, res|
          req.invalid_id_token! 'Expired or Invalid Format'
        end
      end
      it do
        status, header, response = app.call(env)
        status.should == 400
        response.body.first.should include '"error":"invalid_id_token"'
      end
    end
  end
end