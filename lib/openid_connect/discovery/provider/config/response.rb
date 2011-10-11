module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Response < SWD::Resource
          include AttrOptional

          attr_reader :raw
          attr_optional :version, :issuer
          attr_optional :authorization_endpoint, :token_endpoint, :user_info_endpoint
          attr_optional :check_id_endpoint, :refresh_session_endpoint, :end_session_endpoint
          attr_optional :jwk_document, :x509_url, :registration_endpoint
          attr_optional :scopes_supported, :flows_supported, :iso29115_supported, :identifiers_supported

          def initialize(hash)
            optional_attributes.each do |key|
              self.send "#{key}=", hash[key]
            end
            @raw = hash
          end
        end
      end
    end
  end
end