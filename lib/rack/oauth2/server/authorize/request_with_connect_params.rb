class Rack::OAuth2::Server::Authorize
  module RequestWithConnectParams
    # NOTE: nonce is REQUIRED, but define optional attributes not to break rack-oauth2 for now
    CONNECT_EXT_PARAMS = [:nonce, :display, :prompt, :request, :request_uri]

    def self.included(klass)
      klass.send :attr_optional, *CONNECT_EXT_PARAMS
      klass.class_eval do
        def initialize_with_connect_params(env)
          initialize_without_nonce env
          CONNECT_EXT_PARAMS.each do |attribute|
            self.send :"#{attribute}=", params[attribute.to_s]
          end
        end
        alias_method_chain :initialize, :connect_params
      end
    end
  end
  Request.send :include, RequestWithConnectParams
end