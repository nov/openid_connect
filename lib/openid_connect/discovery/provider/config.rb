module OpenIDConnect
  module Discovery
    module Provider
      class Config
        def self.discover!(host, cache_options = {})
          principal = Principal.parse(identifier)
          Resource.new(principal.host).discover!(cache_options)
        rescue SWD::Exception => e
          raise DiscoveryFailed.new(e.message)
        end
      end
    end
  end
end