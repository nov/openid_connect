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
            :userinfo_endpoint,
            :refresh_session_endpoint,
            :check_session_endpoint,
            :end_session_endpoint,
            :jwk_url,
            :jwk_encryption_url,
            :x509_url,
            :x509_encryption_url,
            :registration_endpoint,
            :scopes_supported,
            :response_types_supported,
            :acr_values_supported,
            :subject_types_supported,
            :claims_supported,
            :userinfo_signing_alg_values_supported,
            :userinfo_encryption_alg_values_supported,
            :userinfo_encryption_enc_values_supported,
            :id_token_signing_alg_values_supported,
            :id_token_encryption_alg_values_supported,
            :id_token_encryption_enc_values_supported,
            :request_object_signing_alg_values_supported,
            :request_object_encryption_alg_values_supported,
            :request_object_encryption_enc_values_supported,
            :token_endpoint_auth_methods_supported,
            :token_endpoint_auth_signing_alg_values_supported
          )
          [
            :userinfo_endpoint,
            :userinfo_signing_alg_values_supported,
            :userinfo_encryption_alg_values_supported,
            :userinfo_encryption_enc_values_supported
          ].each do |userinfo_attribute|
            user_info_attribute = userinfo_attribute.to_s.sub('userinfo', 'user_info').to_sym
            alias_method user_info_attribute, userinfo_attribute
            alias_method :"#{user_info_attribute}=", userinfo_attribute
          end

          def initialize(hash)
            optional_attributes.each do |key|
              self.send "#{key}=", hash[key]
            end
            self.userinfo_endpoint ||= hash[:user_info_endpoint]
            self.userinfo_signing_alg_values_supported ||= hash[:user_info_signing_alg_values_supported]
            self.userinfo_encryption_alg_values_supported ||= hash[:user_info_encryption_alg_values_supported]
            self.userinfo_encryption_enc_values_supported ||= hash[:user_info_encryption_enc_values_supported]
            self.version ||= '3.0'
            @raw = hash
          end

          def as_json(options = {})
            hash = optional_attributes.inject({}) do |hash, _attr_|
              hash.merge(
                _attr_ => self.send(_attr_)
              )
            end
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