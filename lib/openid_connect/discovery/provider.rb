module OpenIDConnect
  module Discovery
    module Provider
      SERVICE_URI = 'http://openid.net/specs/connect/1.0/issuer'

      def self.discover!(identifier)
        Principal.parse(identifier).discover!
      end
    end
  end
end

require 'openid_connect/discovery/provider/config'