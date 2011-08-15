require 'jwt'

module OpenIDConnect
  class ResponseObject
    class IdToken < ResponseObject
      attr_required :iss, :user_id, :aud, :exp
      attr_optional :iso29115, :nonce, :issued_to, :secret

      def to_jwt
        raise Exception.new('Secret Required') unless secret
        JWT.encode as_json, secret
      end

      def self.from_jwt(jwt, secret)
        new JWT.decode(jwt, secret).with_indifferent_access.merge(:secret => secret)
      end

      private

      def hidden_attributes
        :secret
      end
    end
  end
end