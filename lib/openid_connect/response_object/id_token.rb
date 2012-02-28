require 'json/jwt'

module OpenIDConnect
  class ResponseObject
    class IdToken < ConnectObject
      class InvalidToken < Exception; end

      attr_required :iss, :user_id, :aud, :exp, :nonce
      attr_optional :acr, :auth_time

      validates :acr, :inclusion => {:in => [0, 1, 2, 3, 4]}, :allow_nil => true

      def initialize(attributes = {})
        super
        (all_attributes - [:exp]).each do |key|
          self.send "#{key}=", self.send(key).try(:to_s)
        end
        @exp = @exp.to_i
      end

      def verify!(expected = {})
        exp.to_i >= Time.now.to_i &&
        iss == expected[:issuer] &&
        aud == expected[:client_id] &&
        nonce == expected[:nonce] or
        raise InvalidToken.new('Invalid ID Token')
      end

      include JWTnizable
      class << self
        def decode(jwt_string, key_or_client)
          case key_or_client
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