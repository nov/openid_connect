require 'spec_helper'

describe OpenIDConnect::ResponseObject::UserInfo::OpenID do
  let(:klass) { OpenIDConnect::ResponseObject::UserInfo::OpenID }

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [] }
    its(:optional_attributes) do
      should == [
        # Boolean
        :verified,
        # String
        :id, :name, :given_name, :family_name, :middle_name, :nickname,
        # Formatted String
        :gender, :zoneinfo, :locale, :phone_number,
        # Date/Time
        :birthday, :updated_time,
        # URL
        :profile, :picture, :website,
        # Email
        :email,
        # Object
        :address
      ]
    end
  end
end