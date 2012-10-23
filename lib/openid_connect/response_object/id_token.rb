require 'json/jwt'

module OpenIDConnect
  class ResponseObject
    class IdToken < ConnectObject
      class InvalidToken < Exception; end

      attr_required :iss, :user_id, :aud, :exp, :iat
      attr_optional :acr, :auth_time, :nonce, :user_jwk, :at_hash, :c_hash
      attr_accessor :access_token, :code

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
      def to_jwt_with_at_hash_and_c_hash(key, algorithm = :RS256, &block)
        hash_length = algorithm.to_s[2, 3].to_i
        if access_token
          token = case access_token
          when Rack::OAuth2::AccessToken
            access_token.access_token
          else
            access_token
          end
          self.at_hash = left_half_hash_of token, hash_length
        end
        if code
          self.c_hash = left_half_hash_of code, hash_length
        end
        to_jwt_without_at_hash_and_c_hash key, algorithm, &block
      end
      alias_method_chain :to_jwt, :at_hash_and_c_hash

      private

      def left_half_hash_of(string, hash_length)
        digest = OpenSSL::Digest::Digest.new("SHA#{hash_length}").digest string
        UrlSafeBase64.encode64 digest[0, hash_length / 2]
      end

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
          raise InvalidToken.new('Missing user_jwk') if jwk.blank?
          public_key = JSON::JWK.decode jwk
          user_id_base_string = case public_key
          when OpenSSL::PKey::RSA
            [jwk[:mod], jwk[:xpo]].join
          when OpenSSL::PKey::EC
            raise NotImplementedError.new('Not Implemented Yet')
          else
            # Shouldn't reach here. All unknown algorithm error should occurs when decoding JWK
            raise InvalidToken.new('Unknown Algorithm')
          end
          expected_user_id = UrlSafeBase64.encode64 OpenSSL::Digest::SHA256.digest(user_id_base_string)
          raise InvalidToken.new('Invalid user_id') unless jwt[:user_id] == expected_user_id
          jwt = JSON::JWT.decode jwt_string, public_key
          new jwt
        end
      end
    end
  end
end