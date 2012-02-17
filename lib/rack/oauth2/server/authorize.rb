module Rack
  module OAuth2
    module Server
      class Authorize
        class Request
          attr_required :nonce

          def initialize_with_nonce(env)
            initialize_without_nonce env
            @nonce = params['nonce']
          end
        end
      end
    end
  end
end