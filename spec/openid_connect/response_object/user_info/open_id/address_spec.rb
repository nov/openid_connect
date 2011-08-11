require 'spec_helper'

describe OpenIDConnect::ResponseObject::UserInfo::OpenID::Address do
  let(:klass) { OpenIDConnect::ResponseObject::UserInfo::OpenID::Address }

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [] }
    its(:optional_attributes) { should == [:formatted, :street_address, :locality, :region, :postal_code, :country] }
  end
end