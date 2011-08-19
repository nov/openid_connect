module OpenIDConnect
  module Discovery
    class Principal
      class URI < Principal
        def initialize(identifier)
          uri = normalize(identifier)
          @identifier = uri.to_s
          @host = uri.host
        end

        private

        def normalize(identifier)
          uri = ::URI.parse(identifier)
          if uri.host.blank?
            uri.host, uri.path = uri.path.split('/', 2)
            uri.path = File.join('/', uri.path)
          end
          uri.scheme ||= 'https'
          uri
        end
      end
    end
  end
end