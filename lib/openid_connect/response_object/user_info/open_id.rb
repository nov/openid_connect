module OpenIDConnect
  class ResponseObject
    module UserInfo
      class OpenID < ConnectObject
        attr_optional(
          :user_id,
          :name,
          :family_name,
          :given_name,
          :middle_name,
          :nickname,
          :preferred_username,
          :profile,
          :picture,
          :website,
          :gender,
          :birthday,
          :zoneinfo,
          :locale,
          :updated_time,
          :email,
          :email_verified,
          :address,
          :phone_number
        )

        validates :email_verified, inclusion: {in: [true, false]},                             allow_nil: true
        validates :gender,         inclusion: {in: ['male', 'female']},                        allow_nil: true
        validates :zoneinfo,       inclusion: {in: TZInfo::TimezoneProxy.all.collect(&:name)}, allow_nil: true
        validates :profile, :picture, :website, url: true, allow_nil: true
        validates :email, email: true, allow_nil: true
        validate :validate_address
        validate :require_at_least_one_attributes
        # TODO: validate locale

        def initialize(attributes = {})
          super
          (all_attributes - [:email_verified, :address]).each do |key|
            self.send "#{key}=", self.send(key).try(:to_s)
          end
        end

        def validate_address
          errors.add :address, address.errors.full_messages.join(', ') if address.present? && !address.valid?
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