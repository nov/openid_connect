module OpenIDConnect
  class WorkplaceIdAccessToken < Rack::OAuth2::AccessToken::Bearer

    attr_required :client
    attr_required :id_token

    def initialize(attributes = {})
      @client = attributes["client"]
      @id_token = attributes['id_token']
    end

    def userinfo!(params = {})
      # returning this object forces omniauth_openid_connect to
      # parse userinfo from the id_token
      ::OpenIDConnect::HttpError.new(200)
    end

  end
end
