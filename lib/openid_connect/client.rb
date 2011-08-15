module OpenIDConnect
  class Client < Rack::OAuth2::Client
    attr_optional :introspection_endpoint, :user_info_endpoint, :access_token

    def initialize(attributes = {})
      super
      @user_info_endpoint     ||= '/user_info'
      @introspection_endpoint ||= '/id_tokens'
    end

    def authorization_uri(params = {})
      params[:response_type] ||= :token
      params[:scope] = setup_required_scope params[:scope]
      Rack::OAuth2::Util.redirect_uri absolute_uri_for(authorization_endpoint), :query, params.merge(
        :client_id => self.identifier,
        :redirect_uri => self.redirect_uri
      )
    end

    def access_token!
      @access_token = super
    end

    def user_info!(scheme = :openid)
      klass = case scheme
      when :openid
        UserInfo::OpenID
      else
        raise "Unknown Scheme: #{scheme}"
      end
      klass.new resource_request do
        access_token.get absolute_uri_for(user_info_endpoint)
      end
    end

    def id_token!
      IdToken.new resource_request do
        access_token.get absolute_uri_for(introspection_endpoint)
      end
    end

    private

    def setup_required_scope(scopes)
      scopes = Array(scopes).join(' ').split(' ')
      if scopes.include?('openid')
        scopes
      else
        (scopes << 'openid')
      end.join(' ')
    end

    def access_token_requied!
      raise OpenIDConnect::Exception.new('Access Token Requied') unless access_token
    end

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