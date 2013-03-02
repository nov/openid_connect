module OpenIDConnect
  module Discovery
    REL_VALUE = 'http://openid.net/specs/connect/1.0/issuer'

    class InvalidIdentifier < Exception; end
    class DiscoveryFailed < Exception; end
  end
end

require 'openid_connect/discovery/provider'