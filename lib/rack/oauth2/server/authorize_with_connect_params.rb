module Rack
  module OAuth2
    module Server
      class Authorize
        class Request
          CONNECT_EXT_PARAMS = {
            :required => [:nonce],
            :optional => [:display, :prompt, :request, :request_uri]
          }
          attr_required *CONNECT_EXT_PARAMS[:required]
          attr_optional *CONNECT_EXT_PARAMS[:optional]

          def initialize_with_connect_params(env)
            initialize_without_nonce env
            (CONNECT_EXT_PARAMS[:required] + CONNECT_EXT_PARAMS[:optional]).each do |attribute|
              self.send :"#{attribute}=", params[attribute.to_s]
            end
          end
          alias_method_chain :initialize, :connect_params
        end
      end
    end
  end
end