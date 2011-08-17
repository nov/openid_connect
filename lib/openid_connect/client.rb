require 'rack/oauth2/client/error'
require 'rack/oauth2/client/grant'

module OpenIDConnect
  class Client < Rack::OAuth2::Client
    attr_optional :introspection_endpoint, :user_info_endpoint

    def initialize(attributes = {})
      super
      @user_info_endpoint     ||= '/user_info'
      @introspection_endpoint ||= '/id_token'
    end

    def authorization_uri(params = {})
      params[:response_type] ||= :token
      params[:scope] = setup_required_scope params[:scope]
      Rack::OAuth2::Util.redirect_uri absolute_uri_for(authorization_endpoint), :query, params.merge(
        :client_id => self.identifier,
        :redirect_uri => self.redirect_uri
      )
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

    def handle_success_response(response)
      token_hash = JSON.parse(response.body).with_indifferent_access
      case token_type = token_hash[:token_type].try(:downcase)
      when 'bearer'
        AccessToken.new token_hash.merge(client: self)
      else
        raise Exception.new("Unexpected Token Type: #{token_type}")
      end
    rescue JSON::ParserError
      raise Exception.new("Unknown Token Type")
    end
  end
end