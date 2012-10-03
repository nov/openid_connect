require 'json/jwt'

module OpenIDConnect
  class ResponseObject
    class IdToken < ConnectObject
      class InvalidToken < Exception; end

      attr_required :iss, :user_id, :aud, :exp, :iat
      attr_optional :acr, :auth_time, :nonce, :user_jwk, :at_hash, :c_hash

      def initialize(attributes = {})
        super
        (all_attributes - [:exp, :iat, :auth_time, :user_jwk]).each do |key|
          self.send "#{key}=", self.send(key).try(:to_s)
        end
        self.raw_attributes = attributes
      end

      def verify!(expected = {})
        exp.to_i > Time.now.to_i &&
        iss == expected[:issuer] &&
        aud == expected[:client_id] &&
        nonce == expected[:nonce] or
        raise InvalidToken.new('Invalid ID Token')
      end

      include JWTnizable
      class << self
        def decode(jwt_string, key)
          new JSON::JWT.decode(jwt_string, key)
        end
      end
    end
  end
end