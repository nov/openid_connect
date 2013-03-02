module OpenIDConnect
  module Discovery
    module Provider
      module Issuer
        def issuer
          self.link_for(REL_VALUE)[:href]
        end
      end

      def self.discover!(identifier)
        resource = case identifier
        when /^acct:/, /@/, /^https?:\/\//
          identifier
        else
          "https://#{identifier}"
        end
        response = WebFinger.discover!(
          resource,
          rel: REL_VALUE
        )
        response.extend Issuer
        response
      rescue WebFinger::Exception => e
        raise DiscoveryFailed.new(e.message)
      end
    end
  end
end

require 'openid_connect/discovery/provider/config'