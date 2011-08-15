module OpenIDConnect
  class AccessToken < Rack::OAuth2::AccessToken::Bearer
    attr_required :client

    def user_info!(scheme = :openid)
      klass = case scheme
      when :openid
        ResponseObject::UserInfo::OpenID
      else
        raise "Unknown Scheme: #{scheme}"
      end
      hash = resource_request do
        get client.user_info_uri
      end
      klass.new hash
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
      when 401
        raise OpenIDConnect::Unauthorized.new('Access Token Invalid or Expired')
      else
        raise OpenIDConnect::BadRequest.new('API Access Faild')
      end
    end
  end
end