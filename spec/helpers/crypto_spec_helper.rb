module CryptoSpecHelper
  def rsa_key1
    @rsa_key1 ||= OpenSSL::PKey::RSA.generate 2048
  end

  def rsa_key2
    @rsa_key2 ||= OpenSSL::PKey::RSA.generate 2048
  end

  def public_keys_hash
    @public_key ||= [{:kid => '1', :key => rsa_key1.public_key}, {:kid => '2', :key => rsa_key2.public_key}]
  end

  def public_key
    @public_key ||= rsa_key1.public_key
  end

  def private_key
    @private_key ||= OpenSSL::PKey::RSA.new rsa_key1.export(OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC'), 'pass-phrase'), 'pass-phrase'
  end

  def private_key2
    @private_key ||= OpenSSL::PKey::RSA.new rsa_key2.export(OpenSSL::Cipher::Cipher.new('DES-EDE3-CBC'), 'pass-phrase'), 'pass-phrase'
  end

  def ec_key
    @ec_key ||= OpenSSL::PKey::EC.new('prime256v1').generate_key
  end

  def ec_public_key
    unless @ec_public_key
      @ec_public_key = OpenSSL::PKey::EC.new ec_key
      @ec_public_key.private_key = nil
    end
    @ec_public_key
  end

  def ec_private_key
    ec_key
  end
end

include CryptoSpecHelper