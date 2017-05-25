module OpenIDConnect
  class Client < Rack::OAuth2::Client
    attr_optional :userinfo_endpoint, :end_session_endpoint, :expires_in

    def initialize(attributes = {})
      super attributes
      self.userinfo_endpoint ||= '/userinfo'
    end

    def authorization_uri(params = {})
      params[:scope] = setup_required_scope params[:scope]
      params[:prompt] = Array(params[:prompt]).join(' ')
      super
    end

    def userinfo_uri
      absolute_uri_for userinfo_endpoint
    end

    def end_session_uri(after_sign_out_path = nil)
      Rack::OAuth2::Util.redirect_uri absolute_uri_for(end_session_endpoint), :query, {post_logout_redirect_uri: after_sign_out_path}
    end

    private

    def setup_required_scope(scopes)
      _scopes_ = Array(scopes).join(' ').split(' ')
      _scopes_ << 'openid' unless _scopes_.include?('openid')
      _scopes_
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

Dir[File.dirname(__FILE__) + '/client/*.rb'].each do |file|
  require file
end
