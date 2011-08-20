module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Response < SWD::Resource
          attr_optional :authorization_endpoint, :token_endpoint, :registration_endpoint
          attr_optional :user_info_endpoint, :check_session_endpoint, :refresh_session_endpoint, :end_session_endpoint
          attr_optional :jwk_document, :scopes_supported, :flows_supported, :iso29115_supported

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