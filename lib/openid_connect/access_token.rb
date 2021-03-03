module OpenIDConnect
  class AccessToken < Rack::OAuth2::AccessToken::Bearer
    attr_required :client
    attr_optional :id_token

    def initialize(attributes = {})
      super
      @token_type = :bearer
    end

    def userinfo!(params = {}, client_auth_method: nil)
      hash = resource_request do
        if client_auth_method == :mtls
          get_info_with_headers(params)
        else
          get client.userinfo_uri, params
        end
      end

      ResponseObject::UserInfo.new hash
    end

    private

    def get_info_with_headers(params)
      headers = { 'Authorization' => "Bearer #{access_token}" }
      http_client = Rack::OAuth2.http_client
      http_client.ssl_config.client_key = client.private_key
      http_client.ssl_config.client_cert = client.certificate

      http_client.get(client.userinfo_uri, params, headers)
    end

    def resource_request
      res = yield
      case res.status
      when 200
        JSON.parse(res.body).with_indifferent_access
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
