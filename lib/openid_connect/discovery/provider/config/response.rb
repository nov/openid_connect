module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Response < SWD::Resource
          include AttrOptional

          attr_reader :raw
          attr_required(
            :issuer,
            :jwks_uri,
            :response_types_supported,
            :subject_types_supported,
            :id_token_signing_alg_values_supported
          )
          attr_optional(
            :authorization_endpoint,
            :token_endpoint,
            :userinfo_endpoint,
            :check_session_endpoint,
            :end_session_endpoint,
            :registration_endpoint,
            :scopes_supported,
            :grant_types_supported,
            :acr_values_supported,
            :userinfo_signing_alg_values_supported,
            :userinfo_encryption_alg_values_supported,
            :userinfo_encryption_enc_values_supported,
            :id_token_encryption_alg_values_supported,
            :id_token_encryption_enc_values_supported,
            :request_object_signing_alg_values_supported,
            :request_object_encryption_alg_values_supported,
            :request_object_encryption_enc_values_supported,
            :token_endpoint_auth_methods_supported,
            :token_endpoint_auth_signing_alg_values_supported,
            :display_values_supported,
            :claim_types_supported,
            :claims_supported,
            :service_documentation,
            :claims_locales_supported,
            :ui_locales_supported,
            :claims_parameter_supported,
            :request_parameter_supported,
            :request_uri_parameter_supported,
            :require_request_uri_registration,
            :op_policy_uri,
            :op_tos_uri
          )

          def initialize(hash)
            (required_attributes + optional_attributes).each do |key|
              self.send "#{key}=", hash[key]
            end
            @raw = hash
          end

          def as_json(options = {})
            hash = (required_attributes + optional_attributes).inject({}) do |hash, _attr_|
              hash.merge(
                _attr_ => self.send(_attr_)
              )
            end
            hash.delete_if do |key, value|
              value.nil?
            end
          end

          def jwks
            if jwks_uri
              jwk_set = JSON.parse OpenIDConnect.http_client.get_content(endpoint), symbolize_names: true
              JSON::JWK.decode jwk_set[:keys].first
            end
          end
        end
      end
    end
  end
end