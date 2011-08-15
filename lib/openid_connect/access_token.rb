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
      klass.new resource_request do
        get absolute_uri_for(user_info_endpoint)
      end
    end

    def id_token!
      ResponseObject::IdToken.new resource_request do
        get absolute_uri_for(introspection_endpoint)
      end
    end

    private

    def resource_request
      access_token_requied!
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