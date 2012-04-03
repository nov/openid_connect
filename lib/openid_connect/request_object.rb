module OpenIDConnect
  class RequestObject < ConnectObject
    attr_optional :client_id, :response_type, :redirect_uri, :scope, :state, :nonce, :display, :prompt, :user_info, :id_token
    validate :require_at_least_one_attributes

    def initialize(attributes = {})
      attributes[:user_info] ||= attributes[:userinfo]
      super attributes
    end

    def id_token=(attributes = {})
      @id_token = IdToken.new(attributes) if attributes.present?
    end

    def user_info=(attributes = {})
      @user_info = UserInfo.new(attributes) if attributes.present?
    end

    def as_json_with_user_info(options = {})
      hash = as_json_without_user_info options
      if hash.include?(:user_info)
        hash[:userinfo] = hash.delete(:user_info)
      end
      hash.with_indifferent_access
    end
    alias_method_chain :as_json, :user_info

    include JWTnizable
    class << self
      def decode(jwt_string, key)
        new JSON::JWT.decode(jwt_string, key)
      end

      def fetch(request_uri, key)
        jwt_string = OpenIDConnect.http_client.get_content(request_uri)
        decode jwt_string, key
      end
    end
  end
end

require 'openid_connect/request_object/claimable'
require 'openid_connect/request_object/id_token'
require 'openid_connect/request_object/user_info'