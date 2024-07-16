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

    def to_mtls(attributes = {})
      (required_attributes + optional_attributes).each do |key|
        attributes[key] = self.send(key)
      end
      MTLS.new attributes
    end

    private

    def resource_request
      res = yield
      case res.status
      when 200
        res.body.with_indifferent_access
      when 400
        raise BadRequest.new('API Access Failed', res)
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

require 'openid_connect/access_token/mtls'
