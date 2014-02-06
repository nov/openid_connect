module OpenIDConnect
  class RequestObject < ConnectObject
    include JWTnizable

    attr_optional :client_id, :response_type, :redirect_uri, :scope, :state, :nonce, :display, :prompt, :userinfo, :id_token
    validate :require_at_least_one_attributes

    def id_token=(attributes = {})
      @id_token = IdToken.new(attributes) if attributes.present?
    end

    def userinfo=(attributes = {})
      @userinfo = UserInfo.new(attributes) if attributes.present?
    end

    def as_json_with_mixed_keys(options = {})
      hash = as_json_without_mixed_keys options
      hash.with_indifferent_access
    end
    alias_method_chain :as_json, :mixed_keys

    class << self
      def decode(jwt_string, key = nil)
        new JSON::JWT.decode(jwt_string, key)
      end

      def fetch(request_uri, key = nil)
        jwt_string = OpenIDConnect.http_client.get_content(request_uri)
        decode jwt_string, key
      end
    end
  end
end

require 'openid_connect/request_object/claimable'
require 'openid_connect/request_object/id_token'
require 'openid_connect/request_object/user_info'
