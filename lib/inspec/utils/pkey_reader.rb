require "dynamo/input"

module PkeyReader
  def read_pkey(filecontent, passphrase)
    raise_if_unset(passphrase)

    OpenSSL::PKey.read(filecontent, passphrase)
  rescue OpenSSL::PKey::PKeyError
    raise Dynamo::Exceptions::ResourceFailed, "passphrase error"
  end

  def raise_if_unset(passphrase)
    if passphrase.is_a? Dynamo::Input::NO_VALUE_SET
      raise Dynamo::Exceptions::ResourceFailed, "Please provide a value for input for openssl key passphrase"
    end
  end
end
