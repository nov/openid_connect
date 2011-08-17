require 'rack/oauth2/client/error'
require 'rack/oauth2/client/grant'

module OpenIDConnect
  class Client < Rack::OAuth2::Client
    attr_optional :introspection_endpoint, :user_info_endpoint

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
      token = super
      raise Exception.new("Unexpected Token Type: #{token.token_type}") unless token.token_type == :bearer
      AccessToken.new token.token_response.merge(:client => self)
    end

    def introspection_uri
      absolute_uri_for introspection_endpoint
    end

    def user_info_uri
      absolute_uri_for user_info_endpoint
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
  end
end