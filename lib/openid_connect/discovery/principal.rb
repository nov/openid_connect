module OpenIDConnect
  module Discovery
    class Principal
      attr_reader :identifier, :host
      delegate :discover!, :to => :identifier

      def initialize(identifier)
        raise InvalidIdentifier if identifier.blank?
        identifier_type = case identifier
        when /^(=|@|!)/
          XRI
        when /@/
          Email
        else
          URI
        end
        @identifier = identifier_type.new identifier
      end

      def discover!
        SWD.discover!(
          :principal => identifier,
          :service => 'http://openid.net/specs/connect/1.0/issuer',
          :host => host
        )
      rescue SWD::Exception => e
        raise DiscoveryFailed.new(e.message)
      end
    end
  end
end

require 'openid_connect/discovery/principal/email'
require 'openid_connect/discovery/principal/uri'
require 'openid_connect/discovery/principal/xri'