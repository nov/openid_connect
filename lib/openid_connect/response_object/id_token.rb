require 'json/jwt'

module OpenIDConnect
  class ResponseObject
    class IdToken < ConnectObject
      class InvalidToken < Exception; end

      attr_required :iss, :sub, :aud, :exp, :iat
      attr_optional :acr, :auth_time, :nonce, :sub_jwk, :at_hash, :c_hash
      attr_accessor :access_token, :code
      alias_method :subject, :sub
      alias_method :subject=, :sub=

      def initialize(attributes = {})
        super
        (all_attributes - [:aud, :exp, :iat, :auth_time, :sub_jwk]).each do |key|
          self.send "#{key}=", self.send(key).try(:to_s)
        end
        self.auth_time = auth_time.to_i unless auth_time.nil?
      end

      def verify!(expected = {})
        exp.to_i > Time.now.to_i &&
        iss == expected[:issuer] &&
        Array(aud).include?(expected[:audience] || expected[:client_id]) && # aud(ience) can be a string or an array of strings
        nonce == expected[:nonce] or
        raise InvalidToken.new('Invalid ID Token')
      end

      include JWTnizable
      def to_jwt(key, algorithm = :RS256, &block)
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
        super
      end

      private

      def left_half_hash_of(string, hash_length)
        digest = OpenSSL::Digest.new("SHA#{hash_length}").digest string
        UrlSafeBase64.encode64 digest[0, hash_length / (2 * 8)]
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
          jwk = JSON::JWK.new jwt[:sub_jwk]
          raise InvalidToken.new('Missing sub_jwk') if jwk.blank?
          raise InvalidToken.new('Invalid subject') unless jwt[:sub] == jwk.thumbprint
          jwt.verify! jwk
          new jwt
        end

        def self_issued(attributes = {})
          attributes[:sub_jwk] ||= JSON::JWK.new attributes.delete(:public_key)
          _attributes_ = {
            iss: 'https://self-issued.me',
            sub: JSON::JWK.new(attributes[:sub_jwk]).thumbprint
          }.merge(attributes)
          new _attributes_
        end
      end
    end
  end
end
