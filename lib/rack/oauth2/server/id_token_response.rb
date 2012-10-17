module Rack::OAuth2::Server
  module IdTokenResponse
    def self.included(klass)
      klass.send :attr_optional, :id_token
      klass.class_eval do
        def protocol_params_location
          :fragment
        end

        def protocol_params_with_id_token
          protocol_params_without_id_token.merge(
            id_token: id_token
          )
        end
        alias_method_chain :protocol_params, :id_token
      end
    end
  end
  Token::Response.send :include, IdTokenResponse
end

require 'rack/oauth2/server/authorize/extension/code_and_id_token'
require 'rack/oauth2/server/authorize/extension/code_and_token'
require 'rack/oauth2/server/authorize/extension/code_and_id_token_and_token'
require 'rack/oauth2/server/authorize/extension/id_token'
require 'rack/oauth2/server/authorize/extension/id_token_and_token'