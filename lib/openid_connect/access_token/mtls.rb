module OpenIDConnect
  class AccessToken::MTLS < AccessToken
    def initialize(attributes = {})
      super
      http_client.ssl.client_key  = attributes[:private_key] || client.private_key
      http_client.ssl.client_cert = attributes[:certificate] || client.certificate
    end
  end
end