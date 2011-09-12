module OpenIDConnect
  class ResponseObject
    module UserInfo
      class OpenID < ResponseObject
        attr_optional :user_id, :name, :given_name, :family_name, :middle_name, :nickname

        attr_optional :phone_number

        attr_optional :verified, :gender, :zoneinfo, :locale
        validates :verified, :inclusion => {:in => [true, false]},                             :allow_nil => true
        validates :gender,   :inclusion => {:in => ['male', 'female']},                        :allow_nil => true
        validates :zoneinfo, :inclusion => {:in => TZInfo::TimezoneProxy.all.collect(&:name)}, :allow_nil => true
        # TODO: validate locale

        attr_optional :birthday, :updated_time

        attr_optional :profile, :picture, :website
        validates :profile, :picture, :website, :url => true, :allow_nil => true

        attr_optional :email
        validates :email, :email => true, :allow_nil => true

        attr_optional :address
        validate :validate_address

        validate :require_at_least_one_attributes

        def initialize(attributes = {})
          super
          (all_attributes - [:verified, :address]).each do |key|
            self.send "#{key}=", self.send(key).try(:to_s)
          end
        end

        def validate_address
          errors.add :address, 'cannot be blank' unless address.blank? || address.valid?
        end

        def address=(hash_or_address)
          @address = case hash_or_address
          when Hash
            Address.new hash_or_address
          when Address
            hash_or_address
          end
        end
      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/open_id/*.rb'].each do |file| 
  require file
end