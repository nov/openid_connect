module Rack::OAuth2::Server
  module IdTokenResponse
    def self.included(klass)
      klass.send :attr_optional, :id_token, :private_key
      klass.class_eval do
        def jwt_string
          if id_token.is_a? OpenIDConnect::ResponseObject::IdToken
            raise AttrRequired::AttrMissing.new('private_key is required') unless private_key
            id_token.to_jwt private_key
          else
            id_token
          end
        end

        def protocol_params_with_id_token
          protocol_params_without_id_token.merge(
            :id_token => jwt_string
          )
        end
        alias_method_chain :protocol_params, :id_token
      end
    end
  end
  Token::Response.send :include, IdTokenResponse
  Authorize::Token::Response.send :include, IdTokenResponse
end
