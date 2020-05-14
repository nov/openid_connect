require "openssl"

module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Resource < SWD::Resource
          undef_required_attributes :principal, :service

          class Expired < SWD::Resource::Expired; end

          def initialize(uri)
            @host = uri.host
            @port = uri.port unless [80, 443].include?(uri.port)
            @path = File.join uri.path, '.well-known/openid-configuration'
            attr_missing!
          end

          def endpoint
            SWD.url_builder.build [nil, host, port, path, nil, nil]
          rescue URI::Error => e
            raise SWD::Exception.new(e.message)
          end

          private

          def to_response_object(hash)
            Response.new(hash)
          end

          def cache_key
            sha256 = OpenSSL::Digest::SHA256.hexdigest host
            "swd:resource:opneid-conf:#{sha256}"
          end
        end
      end
    end
  end
end