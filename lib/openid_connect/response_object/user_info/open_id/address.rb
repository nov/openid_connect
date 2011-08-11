module OpenIDConnect
  class ResponseObject
    module UserInfo
      class OpenID
        class Address < ResponseObject
          attr_optional :formatted, :street_address, :locality, :region, :postal_code, :country
        end
      end
    end
  end
end