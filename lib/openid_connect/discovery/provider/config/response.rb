module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Response < SWD::Resource
          include AttrOptional

          attr_reader :raw
          attr_optional(
            :version,
            :issuer,
            :authorization_endpoint,
            :token_endpoint,
            :user_info_endpoint,
            :refresh_session_endpoint,
            :end_session_endpoint,
            :jwk_url,
            :jwk_encryption_url,
            :x509_url,
            :x509_encryption_url,
            :registration_endpoint,
            :scopes_supported,
            :response_types_supported,
            :acrs_supported,
            :user_id_types_supported,
            :user_info_algs_supported,
            :id_token_algs_supported,
            :request_object_algs_supported,
            :token_endpoint_auth_types_supported,
            :token_endpoint_auth_algs_supported
          )

          def initialize(hash)
            optional_attributes.each do |key|
              self.send "#{key}=", hash[key]
            end
            @user_info_endpoint ||= hash[:userinfo_endpoint]
            @user_info_algs_supported ||= hash[:userinfo_algs_supported]
            @version ||= '3.0'
            @raw = hash
          end

          def as_json(options = {})
            hash = optional_attributes.inject({}) do |hash, _attr_|
              hash.merge(
                _attr_ => self.send(_attr_)
              )
            end
            hash[:userinfo_endpoint] = hash.delete(:user_info_endpoint)
            hash[:userinfo_algs_supported] = hash.delete(:user_info_algs_supported)
            hash.delete_if do |key, value|
              value.nil?
            end
          end

          def signing_key
            x509_public_key || jwk_public_key
          end

          def encryption_key
            if x509_encryption_url
              x509_public_key :for_encryption
            elsif jwk_encryption_url
              jwk_public_key :for_encryption
            else
              signing_key
            end
          end

          private

          def x509_public_key(for_encryption = false)
            endpoint = if for_encryption
              x509_encryption_url || x509_url
            else
              x509_url
            end
            if endpoint
              cert = OpenSSL::X509::Certificate.new OpenIDConnect.http_client.get_content(endpoint)
              cert.public_key
            end
          end

          def jwk_public_key(for_encryption = false)
            endpoint = if for_encryption
              jwk_encryption_url || jwk_url
            else
              jwk_url
            end
            if endpoint
              jwk_set = JSON.parse OpenIDConnect.http_client.get_content(endpoint), symbolize_names: true
              JSON::JWK.decode jwk_set[:keys].first
            end
          end
        end
      end
    end
  end
end