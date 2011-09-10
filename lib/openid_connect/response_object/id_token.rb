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

      class << self
        def from_jwt(jwt_string, key_or_client)
          attributes = case key_or_client
          when Client
            http_client = HTTPClient.new
            http_client.request_filter << Debugger::RequestFilter
            resource_request do
              http_client.post key_or_client.check_session_uri, :id_token => jwt_string
            end
          else
            JWT.decode(jwt_string, key_or_client).with_indifferent_access
          end
          new attributes
        end

        def resource_request
          res = yield
          case res.status
          when 200
            JSON.parse(res.body).with_indifferent_access
          when 400
            raise BadRequest.new('Check Session Faild', res)
          else
            raise HttpError.new(res.status, 'Unknown HttpError', res)
          end
        end
      end
    end
  end
end