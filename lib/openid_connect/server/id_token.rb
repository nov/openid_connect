module OpenIDConnect
  module Server
    class IdToken < Rack::OAuth2::Server::Abstract::Handler
      def call(env)
        @request  = Request.new(env)
        @response = Response.new(request)
        super.finish
      rescue Rack::OAuth2::Server::Abstract::Error => e
        e.finish
      end

      class Request < Rack::OAuth2::Server::Abstract::Request
        attr_required :id_token

        # NOTE: client_id is required in Rack::OAuth2 and should not exist here.
        undef_method :client_id, :client_id=
        @required_attributes.delete :client_id

        def initialize(env)
          super
          @id_token  = params['id_token']
          attr_missing!
        end
      end

      class Response < Rack::OAuth2::Server::Abstract::Response
        attr_required :id_token

        def protocol_params
          id_token.as_json
        end

        def finish
          attr_missing!
          write Rack::OAuth2::Util.compact_hash(protocol_params).to_json
          header['Content-Type'] = 'application/json'
          header['Cache-Control'] = 'no-store'
          header['Pragma'] = 'no-cache'
          super
        end
      end
    end
  end
end

require 'openid_connect/server/id_token/error'