module OpenIDConnect
  module Discovery
    class InvalidIdentifier < Exception; end
    class DiscoveryFailed < Exception; end

    module Service
      class << self
        def issuer
          'http://openid.net/specs/connect/1.0/issuer'
        end
      end
    end

    class << self
      def discover(identifier)
        Principal.new(identifier).discover!
      end
    end
  end
end