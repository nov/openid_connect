module OpenIDConnect
  module Discovery
    class InvalidIdentifier < Exception; end
    class DiscoveryFailed < Exception; end

    class << self
      def discover!(identifier)
        Principal.new(identifier).discover!
      end
    end
  end
end

require 'openid_connect/discovery/principal'
require 'openid_connect/discovery/config'