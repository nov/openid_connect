module Rack::OAuth2::Server
  module IdTokenResponse
    def self.included(klass)
      klass.send :attr_optional, :id_token
      klass.class_eval do
        def protocol_params_with_id_token
          protocol_params_without_id_token.merge(
            :id_token => id_token.try(:to_jwt)
          )
        end
        alias_method_chain :protocol_params, :id_token
      end
    end
  end
  Token::Response.send :include, IdTokenResponse
  Authorize::Token::Response.send :include, IdTokenResponse
end
