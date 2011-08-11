module OpenIDConnect
  class ResponseObject
    module UserInfo
      class OpenID < ResponseObject
        attr_optional :id, :name, :given_name, :family_name, :middle_name, :nickname

        attr_optional :phone_number

        attr_optional :verified, :gender, :zoneinfo, :locale
        validates_inclusion_of :verified, :in => [true, false], :allow_nil => true
        validates_inclusion_of :gender, :in => [:male, :female], :allow_nil => true
        validates_inclusion_of :zoneinfo, :in => TZInfo::TimezoneProxy.all.collect(&:name), :allow_nil => true
        # TODO: validate locale

        attr_optional :birthday, :updated_time

        attr_optional :profile, :picture, :website
        validates :profile, :picture, :website, :url => true, :allow_nil => true

        attr_optional :email
        validates :email, :email => true, :allow_nil => true

        attr_optional :address
        validates_each :address do |record|
          record.errors.add :address, 'cannot be blank' unless record.address.blank? || record.address.valid?
        end

        validate :require_at_least_one_attributes

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