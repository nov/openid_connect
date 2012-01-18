if RUBY_VERSION >= '1.9'
  require 'cover_me'
  at_exit do
    CoverMe.complete!
  end
end

require 'rspec'
require 'openid_connect'

require 'helpers/webmock_helper'

def rsa
  @rsa ||= OpenSSL::PKey::RSA.generate 2048
end

def public_key
  @public_key ||= rsa.public_key
end

def private_key
  @private_key ||= OpenSSL::PKey::RSA.new rsa.export(OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC'), 'pass-phrase'), 'pass-phrase'
end