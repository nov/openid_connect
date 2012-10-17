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
        should == {version: '3.0'}
      end
    end

    context 'when user_info_endpoint given' do
      let :attributes do
        {user_info_endpoint: 'https://server.example.com/user_info'}
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
        {user_info_algs_supported: [:HS256, :RS256]}
      end
      it do
        should include :userinfo_algs_supported
      end
      it do
        should_not include :user_info_algs_supported
      end
    end
  end

  describe '#signing_key and #encryption_key' do
    subject { config }
    let(:config) { instance }
    let(:attributes) do
      {
        x509_url: x509_url,
        x509_encryption_url: x509_encryption_url,
        jwk_url: jwk_url,
        jwk_encryption_url: jwk_encryption_url
      }.delete_if do |key, value|
        value.nil?
      end
    end
    let(:x509_url)            { nil }
    let(:x509_encryption_url) { nil }
    let(:jwk_url)             { nil }
    let(:jwk_encryption_url)  { nil }

    context 'when x509_url is given' do
      let(:x509_url) { 'http://provider.example.com/x509.pem' }

      context 'when x509_encryption_url is given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }

        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when jwk_encryption_url is given' do
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }

        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from jwk_encryption_url' do
          mock_json :get, jwk_encryption_url, 'public_keys/jwk' do
            config.encryption_key
          end
        end
      end

      context 'when both x509_encryption_url and jwk_encryption_url are given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }

        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when neither x509_encryption_url nor jwk_encryption_url are given' do
        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end
    end

    context 'when jwk_url is given' do
      let(:jwk_url) { 'http://provider.example.com/jwk.json' }

      context 'when x509_encryption_url is given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }

        it 'should fetch signing_key from jwk_url' do
          mock_json :get, jwk_url, 'public_keys/jwk' do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when jwk_encryption_url is given' do
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }

        it 'should fetch signing_key from jwk_url' do
          mock_json :get, jwk_url, 'public_keys/jwk' do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from jwk_encryption_url' do
          mock_json :get, jwk_encryption_url, 'public_keys/jwk' do
            config.encryption_key
          end
        end
      end

      context 'when both x509_encryption_url and jwk_encryption_url are given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }

        it 'should fetch signing_key from jwk_url' do
          mock_json :get, jwk_url, 'public_keys/jwk' do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when neither x509_encryption_url nor jwk_encryption_url are given' do
        it 'should fetch signing_key from jwk_url' do
          mock_json :get, jwk_url, 'public_keys/jwk' do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, jwk_url, 'public_keys/jwk' do
            config.encryption_key
          end
        end
      end
    end

    context 'when both x509_url and jwk_url are given' do
      let(:x509_url) { 'http://provider.example.com/cert.pem' }
      let(:jwk_url) { 'http://provider.example.com/jwk.json' }

      context 'when x509_encryption_url is given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }

        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when jwk_encryption_url is given' do
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }

        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from jwk_encryption_url' do
          mock_json :get, jwk_encryption_url, 'public_keys/jwk' do
            config.encryption_key
          end
        end
      end

      context 'when both x509_encryption_url and jwk_encryption_url are given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }

        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when neither x509_encryption_url nor jwk_encryption_url are given' do
        it 'should fetch signing_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.signing_key
          end
        end

        it 'should fetch encryption_key from x509_url' do
          mock_json :get, x509_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end
    end

    context 'when neither x509_url nor jwk_url are given' do
      context 'when x509_encryption_url is given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }
        its(:signing_key) { should be_nil }

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when jwk_encryption_url is given' do
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }
        its(:signing_key) { should be_nil }

        it 'should fetch encryption_key from jwk_encryption_url' do
          mock_json :get, jwk_encryption_url, 'public_keys/jwk' do
            config.encryption_key
          end
        end
      end

      context 'when both x509_encryption_url and jwk_encryption_url are given' do
        let(:x509_encryption_url) { 'http://provider.example.com/x509_encryption.pem' }
        let(:jwk_encryption_url) { 'http://provider.example.com/jwk_encryption.json' }
        its(:signing_key) { should be_nil }

        it 'should fetch encryption_key from x509_encryption_url' do
          mock_json :get, x509_encryption_url, 'public_keys/x509', format: :pem do
            config.encryption_key
          end
        end
      end

      context 'when neither x509_encryption_url nor jwk_encryption_url are given' do
        its(:signing_key) { should be_nil }
        its(:encryption_key) { should be_nil }
      end
    end
  end
end