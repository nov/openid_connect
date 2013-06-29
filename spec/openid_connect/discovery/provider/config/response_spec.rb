require 'spec_helper'

describe OpenIDConnect::Discovery::Provider::Config::Response do
  let :instance do
    OpenIDConnect::Discovery::Provider::Config::Response.new attributes
  end
  let :minimum_attributes do
    {
      issuer: 'https://server.example.com',
      jwks_uri: 'https://server.example.com/jwks.json',
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
        end.not_to raise_error OpenIDConnect::ValidationFailed
      end
    end
  end

  describe '#jwks' do
    it :TODO
  end
end