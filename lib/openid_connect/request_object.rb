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
      hash
    end
    alias_method_chain :as_json, :user_info

    include JWTnizable
    class << self
      def decode(jwt_string, key)
        new JSON::JWT.decode(jwt_string, key)
      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/request_object/*.rb'].each do |file|
  require file
end