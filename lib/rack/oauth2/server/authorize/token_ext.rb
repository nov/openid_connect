module Rack
  module OAuth2
    module Server
      class Authorize
        class Token
          class Response
            attr_optional :id_token

            def protocol_params_with_id_token
              protocol_params_without_id_token.merge(
                :id_token => id_token.try(:to_jwt)
              )
            end
            alias_method_chain :protocol_params, :id_token
          end
        end
      end
    end
  end
end