module Rack
  module OAuth2
    module Server
      class Authorize
        module Extension
          class CodeAndIdToken < Abstract::Handler
            class << self
              def response_type_for?(response_type)
                response_type.split.sort == ['code', 'id_token']
              end
            end

            def call(env)
              @request  = Request.new env
              @response = Response.new request
              super
            end

            class Request < Authorize::Code::Request
              def initialize(env)
                super
                @response_type = [:code, :id_token]
                attr_missing!
              end
            end

            class Response < Authorize::Code::Response
              include IdTokenResponse
              attr_required :id_token, :private_key

              def protocol_params
                protocol_params_without_id_token
              end

              def redirect_uri_with_credentials_with_id_token
                _redirect_uri_ = URI.parse redirect_uri_with_credentials_without_id_token
                _redirect_uri_.fragment = {
                  :id_token => jwt_string
                }.to_query
                _redirect_uri_.to_s
              end
              alias_method_chain :redirect_uri_with_credentials, :id_token

            end
          end
        end
      end
    end
  end
end