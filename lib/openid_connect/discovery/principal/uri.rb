module OpenIDConnect
  module Discovery
    class Principal
      class URI < Principal
        def initialize(identifier)
          uri = normalize(identifier)
          @identifier = uri.to_s
          @host = uri.host
          @port = uri.port unless [80, 443].include?(uri.port)
        end

        private

        def normalize(identifier)
          identifier = "https://#{identifier}" unless identifier.include?('://')
          uri = ::URI.parse(identifier)
          uri.fragment = nil
          uri
        rescue ::URI::Error => e
          raise InvalidIdentifier.new('Invalid URI')
        end
      end
    end
  end
end