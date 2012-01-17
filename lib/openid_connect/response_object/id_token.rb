require 'json/jwt'

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

      def to_jwt(key, algorithm = :RS256)
        token = JSON::JWT.new as_json
        if algorithm != :none
          token = token.sign key, algorithm
        end
        token.to_s
      end

      class << self
        def decode(jwt_string, key_or_client)
          attributes = case key_or_client
          when Client
            OpenIDConnect::AccessToken.new(
              :client => key_or_client,
              :access_token => jwt_string
            ).id_token!
          else
            new JSON::JWT.decode(jwt_string, key_or_client)
          end
        end
      end
    end
  end
end