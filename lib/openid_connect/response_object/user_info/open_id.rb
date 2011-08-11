module OpenIDConnect
  class ResponseObject
    module UserInfo
      class OpenID < ResponseObject
        # Boolean
        attr_optional :verified

        # String
        attr_optional :id, :name, :given_name, :family_name, :middle_name, :nickname

        # Formatted String
        attr_optional :gender, :zoneinfo, :locale, :phone_number

        # Date/Time
        attr_optional :birthday, :updated_time

        # URL
        attr_optional :profile, :picture, :website

        # Email
        attr_optional :email

        # Object
        attr_optional :address
      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/open_id/*.rb'].each do |file| 
  require file
end