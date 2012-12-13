require 'spec_helper'

describe OpenIDConnect::Client::Registrar do
  subject { instance }
  let(:attributes) { minimum_attributes }
  let(:minimum_attributes) do
    {
      type: :client_associate
    }
  end
  let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint, attributes) }
  let(:endpoint) { 'https://server.example.com/clients' }

  context 'when endpoint given' do
    context 'when attributes given' do
      context 'when type=client_associate' do
        let(:attributes) do
          minimum_attributes
        end
        it { should be_valid }
      end

      context 'when type=client_update' do
        context 'when client_id given' do
          let(:attributes) do
            {
              type: :client_update,
              client_id: 'client.example.com'
            }
          end
          it { should be_valid }
        end

        context 'otherwise' do
          let(:attributes) do
            {
              type: :client_update
            }
          end
          it { should_not be_valid }
        end
      end

      context 'otherwise' do
        let(:attributes) do
          {
            type: :invalid_type
          }
        end
        it { should_not be_valid }
      end
    end

    context 'otherwise' do
      let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint) }
      it do
        expect do
          instance
        end.not_to raise_error
      end
      it { should_not be_valid }
    end
  end

  context 'otherwise' do
    let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint) }
    let(:endpoint) { '' }

    it do
      expect do
        instance
      end.to raise_error AttrRequired::AttrMissing
    end
  end

  describe '#sector_identifier' do
    context 'when sector_identifier_url given' do
      let(:attributes) do
        minimum_attributes.merge(
          sector_identifier_url: 'https://client.example.com/sector_identifier.json'
        )
      end
      its(:sector_identifier) { should == 'client.example.com' }

      context 'when sector_identifier_url is invalid URI' do
        let(:attributes) do
          minimum_attributes.merge(
            sector_identifier_url: ':invalid'
          )
        end
        its(:sector_identifier) { should be_nil }
      end

      context 'when redirect_uris given' do
        let(:attributes) do
          minimum_attributes.merge(
            sector_identifier_url: 'https://client.example.com/sector_identifier.json',
            redirect_uris: 'https://client2.example.com/callback'
          )
        end
        its(:sector_identifier) { should == 'client.example.com' }
      end
    end

    context 'otherwise' do
      context 'when redirect_uris given' do
        context 'when single host' do
          let(:attributes) do
            minimum_attributes.merge(
              redirect_uris: [
                'https://client.example.com/callback/op1',
                'https://client.example.com/callback/op2'
              ].join(' ')
            )
          end
          its(:sector_identifier) { should == 'client.example.com' }
        end

        context 'when multi host' do
          let(:attributes) do
            minimum_attributes.merge(
              redirect_uris: [
                'https://client1.example.com/callback',
                'https://client2.example.com/callback'
              ].join(' ')
            )
          end
          its(:sector_identifier) { should be_nil }
        end

        context 'when invalid URI' do
          let(:attributes) do
            minimum_attributes.merge(
              redirect_uris: ':invalid'
            )
          end
          its(:sector_identifier) { should be_nil }
        end
      end

      context 'otherwise' do
        its(:sector_identifier) { should be_nil }
      end
    end
  end

  describe '#redirect_uris' do
    let(:base_url) { 'http://client.example.com/callback' }
    let(:attributes) { minimum_attributes.merge(redirect_uris: redirect_uri) }

    context 'when query included' do
      let(:redirect_uri) { [base_url, '?foo=bar'].join }
      it { should be_valid }
      its(:redirect_uris) { should == [redirect_uri] }
    end

    context 'when fragment included' do
      let(:redirect_uri) { [base_url, '#foo=bar'].join }
      it { should_not be_valid }
    end
  end

  describe '#contacts' do
    context 'when contacts given' do
      context 'when invalid email included' do
        let(:attributes) do
          minimum_attributes.merge(
            contacts: [
              ':invalid',
              'nov@matake.jp'
            ].join(' ')
          )
        end
        it { should_not be_valid }
      end

      context 'when localhost address included' do
        let(:attributes) do
          minimum_attributes.merge(
            contacts: [
              'nov@localhost',
              'nov@matake.jp'
            ].join(' ')
          )
        end
        it { should_not be_valid }
      end

      context 'otherwise' do
        let(:attributes) do
          minimum_attributes.merge(
            contacts: 'nov@matake.jp'
          )
        end
        it { should be_valid }
      end
    end
  end

  describe '#as_json' do
    context 'when valid' do
      let(:attributes) do
        minimum_attributes.merge(
          redirect_uris: [
            'https://client1.example.com/callback',
            'https://client2.example.com/callback'
          ].join(' ')
        )
      end
      its(:as_json) do
        should == {
          type: 'client_associate',
          redirect_uris: 'https://client1.example.com/callback https://client2.example.com/callback'
        }
      end
    end

    context 'otherwise' do
      let(:attributes) do
        {
          type: :client_update
        }
      end
      it do
        expect do
          instance.as_json
        end.to raise_error OpenIDConnect::ValidationFailed
      end
    end
  end

  describe '#associate!' do
    let(:attributes) do
      {}
    end

    it 'should return OpenIDConnect::Client' do
      mock_json :post, endpoint, 'client/registered', params: {
        type: 'client_associate'
      } do
        client = instance.associate!
        client.should be_instance_of OpenIDConnect::Client
        client.identifier.should == 'client.example.com'
        client.secret.should == 'client_secret'
        client.expires_in.should == 3600
      end
    end

    context 'when failed' do
      it 'should raise OpenIDConnect::Client::Registrar::RegistrationFailed' do
        mock_json :post, endpoint, 'errors/unknown', params: {
          type: 'client_associate'
        }, status: 400 do
          expect do
            instance.associate!
          end.to raise_error OpenIDConnect::Client::Registrar::RegistrationFailed
        end
      end
    end
  end

  describe '#update!' do
    let(:attributes) do
      {
        client_id: 'client.example.com',
        client_secret: 'client_secret'
      }
    end

    it 'should return OpenIDConnect::Client' do
      mock_json :post, endpoint, 'client/updated', params: {
        type: 'client_update',
        client_id: 'client.example.com',
        client_secret: 'client_secret',
        application_name: 'New Name'
      } do
        instance.application_name = 'New Name'
        client = instance.update!
        client.should be_instance_of OpenIDConnect::Client
        client.identifier.should == 'client.example.com'
      end
    end

    context 'when failed' do
      it 'should raise OpenIDConnect::Client::Registrar::RegistrationFailed' do
        mock_json :post, endpoint, 'errors/unknown', params: {
          type: 'client_update',
          client_id: 'client.example.com',
          client_secret: 'client_secret'
        }, status: 400 do
          expect do
            instance.update!
          end.to raise_error OpenIDConnect::Client::Registrar::RegistrationFailed
        end
      end
    end
  end

  describe '#rotate_secret!' do
    let(:attributes) do
      {
        client_id: 'client.example.com',
        client_secret: 'client_secret'
      }
    end

    it 'should return OpenIDConnect::Client' do
      mock_json :post, endpoint, 'client/rotated', params: {
        type: 'rotate_secret',
        client_id: 'client.example.com',
        client_secret: 'client_secret'
      } do
        client = instance.rotate_secret!
        client.should be_instance_of OpenIDConnect::Client
        client.identifier.should == 'client.example.com'
        client.secret.should == 'new_client_secret'
        client.expires_in.should == 3600
      end
    end
  end

  describe '#validate!' do
    context 'when valid' do
      it do
        expect do
          instance.validate!
        end.not_to raise_error OpenIDConnect::ValidationFailed
      end
    end

    context 'otherwise' do
      let(:attributes) do
        {
          type: :client_update
        }
      end
      it do
        expect do
          instance.validate!
        end.to raise_error OpenIDConnect::ValidationFailed
      end
    end
  end

  describe 'http_client' do
    subject { instance.send(:http_client) }

    context 'when access_token given' do
      let(:attributes) do
        minimum_attributes.merge(
          access_token: access_token
        )
      end

      context 'when Rack::OAuth2::AccessToken::Bearer given' do
        let(:access_token) do
          Rack::OAuth2::AccessToken::Bearer.new(access_token: 'access_token')
        end
        it { should be_instance_of Rack::OAuth2::AccessToken::Bearer }
        its(:access_token) { should == 'access_token' }
      end

      context 'otherwise' do
        let(:access_token) { 'access_token' }
        it { should be_instance_of Rack::OAuth2::AccessToken::Bearer }
        its(:access_token) { should == 'access_token' }
      end
    end

    context 'otherwise' do
      it { should be_instance_of HTTPClient }
    end
  end
end