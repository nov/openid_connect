module OpenIDConnect
  class AccessToken < Rack::OAuth2::AccessToken::Bearer
    attr_required :client

    def initialize(attributes = {})
      super
      @token_type = :bearer
    end

    def user_info!(scheme = :openid)
      hash = resource_request do
        get client.user_info_uri
      end
      ResponseObject::UserInfo::OpenID.new hash
    end

    def id_token!
      hash = resource_request do
        get client.introspection_uri
      end
      ResponseObject::IdToken.new hash
    end

    private

    def resource_request
      res = yield
      case res.status
      when 200
        JSON.parse(res.body).with_indifferent_access
      when 400
        raise BadRequest.new('API Access Faild')
      when 401
        raise Unauthorized.new('Access Token Invalid or Expired')
      when 403
        raise Forbidden.new('Insufficient Scope')
      else
        raise HttpError.new(res.status, 'Unknown HttpError')
      end
    end
  end
end