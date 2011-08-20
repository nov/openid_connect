module OpenIDConnect
  module Discovery
    module Provider
      class Config
        class Resource < SWD::Resource
          # NOTE: principal and service are required in SWD::Resource and should not exist here.
          undef_method :principal, :principal=, :service, :service=
          @required_attributes.delete :principal, :service

          class Expired < SWD::Resource::Expired; end

          def initialize(host)
            @host = host
            @path ||= '/.well-known/openid-configuration'
            attr_missing!
          end

          def endpoint
            URI::HTTPS.build [nil, host, 443, path, nil, nil]
          rescue URI::Error => e
            raise SWD::Exception.new(e.message)
          end

          private

          def to_response_object(hash)
            Response.new hash
          end

          def cache_key
            md5 = Digest::MD5.hexdigest [
              principal,
              service,
              host
            ].join(' ')
            "swd:resource:opneid-conf:#{md5}"
          end
        end
      end
    end
  end
end