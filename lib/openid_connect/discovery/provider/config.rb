module OpenIDConnect
  module Discovery
    module Provider
      class Config
        def self.discover!(identifier, cache_options = {})
          principal = Principal.parse(identifier)
          Resource.new(principal).discover!(cache_options)
        rescue SWD::Exception => e
          raise DiscoveryFailed.new(e.message)
        end
      end
    end
  end
end

require 'openid_connect/discovery/provider/config/resource'
require 'openid_connect/discovery/provider/config/response'