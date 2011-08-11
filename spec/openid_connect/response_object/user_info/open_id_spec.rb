require 'spec_helper'

describe OpenIDConnect::ResponseObject::UserInfo::OpenID do
  let(:klass) { OpenIDConnect::ResponseObject::UserInfo::OpenID }

  describe 'attributes' do
    subject { klass }
    its(:required_attributes) { should == [] }
    its(:optional_attributes) do
      should == [
        :id, :name, :given_name, :family_name, :middle_name, :nickname,
        :phone_number,
        :verified, :gender, :zoneinfo, :locale,
        :birthday, :updated_time,
        :profile, :picture, :website,
        :email,
        :address
      ]
    end
  end

  describe 'validations' do
    subject do
      instance = klass.new attributes
      instance.valid?
      instance
    end

    context 'when all attributes are blank' do
      let :attributes do
        {}
      end
      its(:valid?) { should be_false }
      its(:errors) { should include :base }
    end

    [:verified, :gender, :zoneinfo, :locale].each do |one_of_list|
      context "when #{one_of_list} is invalid" do
        let :attributes do
          {one_of_list => 'Out of List'}
        end
        its(:valid?) { should be_false }
        its(:errors) { should include one_of_list }
      end
    end

    [:profile, :picture, :website].each do |url|
      context "when #{url} is invalid" do
        let :attributes do
          {url => 'Invalid'}
        end
        its(:valid?) { should be_false }
        its(:errors) { should include url }
      end
    end

    context 'when address is blank' do
      let :attributes do
        {:address => {}}
      end
      its(:valid?) { should be_false }
      its(:errors) { should include :address }
    end
  end
end