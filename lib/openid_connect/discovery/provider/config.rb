module OpenIDConnect
  module Discovery
    module Provider
      class Config
        def self.discover!(identifier, cache_options = {})
          uri = URI.parse(identifier)
          Resource.new(uri).discover!(cache_options)
        rescue SWD::Exception => e
          raise DiscoveryFailed.new(e.message)
        end
      end
    end
  end
end

require 'openid_connect/discovery/provider/config/resource'
require 'openid_connect/discovery/provider/config/response'