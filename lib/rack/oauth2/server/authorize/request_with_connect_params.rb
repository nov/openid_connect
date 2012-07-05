class Rack::OAuth2::Server::Authorize
  module RequestWithConnectParams
    CONNECT_EXT_PARAMS = [:nonce, :display, :prompt, :request, :request_uri, :id_token]

    def self.included(klass)
      klass.send :attr_optional, *CONNECT_EXT_PARAMS
      klass.class_eval do
        def initialize_with_connect_params(env)
          initialize_without_connect_params env
          CONNECT_EXT_PARAMS.each do |attribute|
            self.send :"#{attribute}=", params[attribute.to_s]
          end
        end
        alias_method_chain :initialize, :connect_params

        def openid_connect_request?
          scope.include?('openid')
        end
      end
    end
  end
  Request.send :include, RequestWithConnectParams
end