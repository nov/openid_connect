require 'simplecov'

SimpleCov.start do
  add_filter 'spec'
end

require 'rspec'
require 'openid_connect'

require 'helpers/crypto_spec_helper'
require 'helpers/webmock_helper'