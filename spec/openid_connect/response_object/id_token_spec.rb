require 'spec_helper'

describe OpenIDConnect::ResponseObject::IdToken do
  let(:klass) { OpenIDConnect::ResponseObject::IdToken }

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [:iss, :user_id, :aud, :exp] }
    its(:optional_attributes) { should == [:iso29115, :nonce, :issued_to] }
  end
end