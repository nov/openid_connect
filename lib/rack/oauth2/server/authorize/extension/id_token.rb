module Rack
  module OAuth2
    module Server
      class Authorize
        module Extension
          class IdToken < Abstract::Handler
            class << self
              def response_type_for?(response_type)
                response_type == 'id_token'
              end
            end

            def call(env)
              @request  = Request.new env
              @response = Response.new request
              super
            end

            class Request < Authorize::Request
              def initialize(env)
                super
                @response_type = :id_token
                attr_missing!
              end

              def error_params_location
                :fragment
              end
            end

            class Response < Authorize::Response
              attr_required :id_token

              def protocol_params
                super.merge :id_token => id_token.to_jwt
              end

              def protocol_params_location
                :fragment
              end
            end
          end
        end
      end
    end
  end
end