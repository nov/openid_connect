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
              include IdTokenResponse
              attr_required :id_token, :private_key

              def protocol_params_location
                :fragment
              end

              def protocol_params
                super.merge(
                  :id_token => jwt_string
                )
              end
            end
          end
        end
      end
    end
  end
end