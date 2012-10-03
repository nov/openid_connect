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
          if key == :self_issued
            decode_self_issued jwt_string
          else
            new JSON::JWT.decode jwt_string, key
          end
        end

        def decode_self_issued(jwt_string)
          jwt = JSON::JWT.decode jwt_string, :skip_verification
          jwk = jwt[:user_jwk]
          public_key = JSON::JWK.decode jwk
          user_id_base_string = case public_key
          when OpenSSL::PKey::RSA
            [jwk[:mod], jwk[:exp]].join
          when OpenSSL::PKey::EC
            raise NotImplementedError.new('Not Implemented Yet')
          else
            # Shouldn't reach here. All unknown algorithm error should occurs when decoding JWK
            raise InvalidToken.new('Unknown Algorithm')
          end
          expected_user_id = UrlSafeBase64.encode64 OpenSSL::Digest::SHA256.digest(user_id_base_string)
          raise InvalidToken.new('Invalid user_id') unless jwt[:user_id] == expected_user_id
          jwt.verify public_key
          new jwt
        end
      end
    end
  end
end