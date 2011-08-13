require 'jwt'

module OpenIDConnect
  class ResponseObject
    class IdToken < ResponseObject
      attr_required :iss, :user_id, :aud, :exp, :secret
      attr_optional :iso29115, :nonce, :issued_to

      def as_json
        (required_attributes + optional_attributes - [:secret]).inject({}) do |hash, key|
          hash.merge! key => self.send(key)
        end.delete_if do |key, value|
          value.nil?
        end
      end

      def to_jwt
        JWT.encode as_json, secret
      end

      def self.from_jwt(jwt, secret)
        new JWT.decode(jwt, secret).with_indifferent_access.merge(:secret => secret)
      end
    end
  end
end