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
  @private_key ||= OpenSSL::PKey::RSA.new rsa.export(OpenSSL::Cipher::Cipher.new('aes256'), 'pass-phrase'), 'pass-phrase'
end