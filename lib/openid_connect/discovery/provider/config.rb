module OpenIDConnect
  module Discovery
    module Provider
      class Config
        def self.discover!(identifier, cache_options = {})
          uri = URI.parse(identifier)
          Resource.new(uri).discover!(cache_options).tap do |response|
            # Some providers expect the issuer to have a trailing slash, some expect it not to
            response.expected_issuer = if response.issuer.end_with?('/')
              identifier.end_with?('/') ? identifier : identifier + '/'
            else
              identifier.end_with?('/') ? identifier[0...-1] : identifier
            end

            response.validate!
          end
        rescue SWD::Exception, ValidationFailed => e
          raise DiscoveryFailed.new(e.message)
        end
      end
    end
  end
end

require 'openid_connect/discovery/provider/config/resource'
require 'openid_connect/discovery/provider/config/response'