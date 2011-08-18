require 'jwt'

module OpenIDConnect
  class ResponseObject
    class IdToken < ResponseObject
      class InvalidToken < Exception; end

      attr_required :iss, :user_id, :aud, :exp
      attr_optional :iso29115, :nonce, :issued_to

      def initialize(attributes = {})
        super
        (all_attributes - [:exp]).each do |key|
          self.send "#{key}=", self.send(key).try(:to_s)
        end
        @exp = @exp.to_i
      end

      def verify!(client_id)
        exp.to_i >= Time.now.to_i && aud == client_id or
        raise InvalidToken.new('Invalid audience or expired')
      end

      def to_jwt(key, algorithm = 'RS256')
        JWT.encode as_json, key, algorithm
      end

      def self.from_jwt(jwt_string, key)
        new JWT.decode(jwt_string, key).with_indifferent_access
      end
    end
  end
end