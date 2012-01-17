require 'json'
require 'logger'
require 'swd'
require 'active_model'
require 'tzinfo'
require 'validate_url'
require 'validate_email'
require 'attr_required'
require 'attr_optional'
require 'rack/oauth2'
require 'rack/oauth2/server/id_token_response'

module OpenIDConnect
  VERSION = ::File.read(
    ::File.join(::File.dirname(__FILE__), '../VERSION')
  )

  def self.logger
    @@logger
  end
  def self.logger=(logger)
    @@logger = logger
  end
  self.logger = Logger.new(STDOUT)
  self.logger.progname = 'OpenIDConnect'

  def self.debugging?
    @@debugging
  end
  def self.debugging=(boolean)
    SWD.debugging = boolean
    Rack::OAuth2.debugging = boolean
    @@debugging = boolean
  end
  def self.debug!
    SWD.debug!
    Rack::OAuth2.debug!
    self.debugging = true
  end
  def self.debug(&block)
    swd_original = SWD.debugging?
    rack_oauth2_original = Rack::OAuth2.debugging?
    original = self.debugging?
    debug!
    yield
  ensure
    SWD.debugging = swd_original
    Rack::OAuth2.debugging = rack_oauth2_original
    self.debugging = original
  end
  self.debugging = false

  def self.http_client
    _http_client_ = HTTPClient.new(
      :agent_name => "OpenIDConnect (#{VERSION})"
    )
    _http_client_.request_filter << Debugger::RequestFilter.new if OpenIDConnect.debugging?
    _http_client_
  end
end

require 'openid_connect/exception'
require 'openid_connect/client'
require 'openid_connect/access_token'
require 'openid_connect/response_object'
require 'openid_connect/server'
require 'openid_connect/discovery'
require 'openid_connect/debugger'