module OpenIDConnect
  class ResponseObject
    class IdToken < ResponseObject
      attr_required :iss, :user_id, :aud, :exp
      attr_optional :iso29115, :nonce, :issued_to

      def to_jwt
        # TODO
        'jwt_header.jwt_part2.jwt_part3'
      end
    end
  end
end