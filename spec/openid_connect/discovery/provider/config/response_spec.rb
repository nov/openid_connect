require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Response do
  let :instance do
    OpenIDConnect::Discovery::Provider::Config::Response.new attributes
  end
  let :jwks_uri do
    'https://server.example.com/jwks.json'
  end
  let :minimum_attributes do
    {
      issuer: 'https://server.example.com',
      jwks_uri: jwks_uri,
      response_types_supported: [
        :code, :id_token, 'token id_token'
      ],
      subject_types_supported: [
        :public, :pairwise
      ],
      id_token_signing_alg_values_supported: [
        :RS256
      ]
    }
  end
  let :attributes do
    minimum_attributes
  end
  subject { instance }

  context 'when required attributes missing' do
    let :attributes do
      {}
    end
    it { should_not be_valid }
  end

  describe '#as_json' do
    subject { instance.as_json }
    it { should == minimum_attributes }
  end

  describe '#validate!' do
    context 'when required attributes missing' do
      let :attributes do
        {}
      end
      it do
        expect do
          instance.validate!
        end.to raise_error OpenIDConnect::ValidationFailed
      end
    end

    context 'otherwise' do
      it do
        expect do
          instance.validate!
        end.not_to raise_error{ |e|
          e.should be_a OpenIDConnect::ValidationFailed
        }
      end
    end
  end

  describe '#jwks' do
    it do
      jwks = mock_json :get, jwks_uri, 'public_keys/jwks' do
        instance.jwks
      end
      jwks.should be_instance_of JSON::JWK::Set
    end
  end

  describe '#public_keys_hash' do
    context 'when jwks without kids' do
      it do
        public_keys_with_kid = mock_json :get, jwks_uri, 'public_keys/jwks' do
          instance.public_keys_hash
        end
        public_keys_with_kid.should be_instance_of Array
        public_keys_with_kid[0].should be_instance_of Hash
        public_keys_with_kid[0][:kid].should be_nil
        public_keys_with_kid[0][:key].should be_instance_of OpenSSL::PKey::RSA
      end
    end

    context 'when jwks with kids' do
      it do
        public_keys_with_kid = mock_json :get, jwks_uri, 'public_keys/jwks_kids' do
          instance.public_keys_hash
        end
        public_keys_with_kid.should be_instance_of Array
        public_keys_with_kid[0].should be_instance_of Hash
        public_keys_with_kid[0][:kid].should eq("a1a985a59256d026e252d5b5faddf9b6b41e32e3")
        public_keys_with_kid[0][:key].should be_instance_of OpenSSL::PKey::RSA
        public_keys_with_kid[1].should be_instance_of Hash
        public_keys_with_kid[1][:kid].should eq("c13a48bfea7287d05629fd6c7c673b23eefafe4f")
        public_keys_with_kid[1][:key].should be_instance_of OpenSSL::PKey::RSA
      end
    end
  end

  describe '#public_keys' do
    it do
      public_keys = mock_json :get, jwks_uri, 'public_keys/jwks' do
        instance.public_keys
      end
      public_keys.should be_instance_of Array
      public_keys.first.should be_instance_of OpenSSL::PKey::RSA
    end
  end
end