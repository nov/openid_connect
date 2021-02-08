module OpenIDConnect
  class AccessToken < Rack::OAuth2::AccessToken::Bearer
    attr_required :client
    attr_optional :id_token

    def initialize(attributes = {})
      super
      @token_type = :bearer
    end

    def userinfo!(params = {})
      hash = resource_request do
        get client.userinfo_uri, params
      end
      ResponseObject::UserInfo.new hash
    end

    private

    def resource_request
      res = yield
      case res.status
      when 200
        hash = case res.content_type
               when 'application/jwt'
                 JSON::JWT.decode(res.body, :skip_verification)
               when 'application/json'
                 JSON.parse(res.body)
               end
        hash&.with_indifferent_access
      when 400
        raise BadRequest.new('API Access Faild', res)
      when 401
        raise Unauthorized.new('Access Token Invalid or Expired', res)
      when 403
        raise Forbidden.new('Insufficient Scope', res)
      else
        raise HttpError.new(res.status, 'Unknown HttpError', res)
      end
    end
  end
end