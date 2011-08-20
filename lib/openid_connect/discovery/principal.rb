require 'swd'

module OpenIDConnect
  module Discovery
    class Principal
      attr_reader :identifier, :host

      def self.parse(identifier)
        raise InvalidIdentifier.new('Identifier Required') if identifier.blank?
        type = case identifier
        when /^(=|@|!)/
          XRI
        when /@/
          Email
        else
          URI
        end
        type.new identifier
      end

      def discover!(cache_options = {})
        SWD.discover!(
          :principal => identifier,
          :service => Provider::SERVICE_URI,
          :host => host,
          :cache => cache_options
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