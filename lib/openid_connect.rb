require 'json'
require 'logger'
require 'faraday'
require 'faraday/follow_redirects'
require 'swd'
require 'webfinger'
require 'active_model'
require 'tzinfo'
require 'validate_url'
require 'email_validator/strict'
require 'mail'
require 'attr_required'
require 'attr_optional'
require 'json/jwt'
require 'rack/oauth2'
require 'rack/oauth2/server/authorize/error_with_connect_ext'
require 'rack/oauth2/server/authorize/request_with_connect_params'
require 'rack/oauth2/server/id_token_response'

module OpenIDConnect
  VERSION = ::File.read(
    ::File.join(::File.dirname(__FILE__), '../VERSION')
  ).chomp

  def self.logger
    @@logger
  end
  def self.logger=(logger)
    @@logger = logger
  end
  self.logger = Logger.new(STDOUT)
  self.logger.progname = 'OpenIDConnect'

  @sub_protocols = [
    SWD,
    WebFinger,
    Rack::OAuth2
  ]
  def self.debugging?
    @@debugging
  end
  def self.debugging=(boolean)
    @sub_protocols.each do |klass|
      klass.debugging = boolean
    end
    @@debugging = boolean
  end
  def self.debug!
    @sub_protocols.each do |klass|
      klass.debug!
    end
    self.debugging = true
  end
  def self.debug(&block)
    sub_protocol_originals = @sub_protocols.inject({}) do |sub_protocol_originals, klass|
      sub_protocol_originals.merge!(klass => klass.debugging?)
    end
    original = self.debugging?
    debug!
    yield
  ensure
    @sub_protocols.each do |klass|
      klass.debugging = sub_protocol_originals[klass]
    end
    self.debugging = original
  end
  self.debugging = false

  def self.http_client
    Faraday.new(headers: {user_agent: "OpenIDConnect (#{VERSION})"}) do |faraday|
      faraday.request :url_encoded
      faraday.request :json
      faraday.response :json
      faraday.adapter Faraday.default_adapter
      http_config&.call(faraday)
      faraday.response :logger, OpenIDConnect.logger, {bodies: true} if debugging?
    end
  end
  def self.http_config(&block)
    @sub_protocols.each do |klass|
      klass.http_config(&block) unless klass.http_config
    end
    @@http_config ||= block
  end

  def self.validate_discovery_issuer=(boolean)
    @@validate_discovery_issuer = boolean
  end

  def self.validate_discovery_issuer
    @@validate_discovery_issuer
  end

  self.validate_discovery_issuer = true
end

require 'openid_connect/exception'
require 'openid_connect/client'
require 'openid_connect/access_token'
require 'openid_connect/jwtnizable'
require 'openid_connect/connect_object'
require 'openid_connect/discovery'
