module Rack
  module OAuth2
    module Server
      class Authorize
        module Extensions
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

            class Request < Authorize::Token::Request
              def initialize(env)
                super
                @response_type = :id_token
                attr_missing!
              end
            end

            class Response < Authorize::Token::Response
            end
          end
        end
      end
    end
  end
end