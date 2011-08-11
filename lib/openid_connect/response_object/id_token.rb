module OpenIDConnect
  class ResponseObject
    class IdToken < ResponseObject
      attr_required :iss, :user_id, :aud, :exp
      attr_optional :iso29115, :nonce, :issued_to
    end
  end
end