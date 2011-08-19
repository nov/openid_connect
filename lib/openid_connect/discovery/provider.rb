module OpenIDConnect
  module Discovery
    module Provider
      def self.discover!(identifier)
        Principal.new(identifier).discover!
      end
    end
  end
end

require 'openid_connect/discovery/provider/config'