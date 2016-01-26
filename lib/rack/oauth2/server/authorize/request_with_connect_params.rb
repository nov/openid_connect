class Rack::OAuth2::Server::Authorize
  module RequestWithConnectParams
    CONNECT_EXT_PARAMS = [:nonce, :display, :prompt, :request, :request_uri, :id_token]

    def self.prepended(klass)
      klass.send :attr_optional, *CONNECT_EXT_PARAMS
    end

    def initialize(env)
      super
      CONNECT_EXT_PARAMS.each do |attribute|
        self.send :"#{attribute}=", params[attribute.to_s]
      end
    end

    def openid_connect_request?
      scope.include?('openid')
    end
  end
  Request.send :prepend, RequestWithConnectParams
end