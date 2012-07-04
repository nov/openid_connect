module Rack
  module OAuth2
    module Server
      class Resource
        module ErrorWithConnectExt
          def invalid_schema!(description = 'The requested schema is invalid or unsupported', options = {})
            bad_request! :invalid_schema, description, options
          end
        end
        Request.send :include, ErrorWithConnectExt
      end
    end
  end
end