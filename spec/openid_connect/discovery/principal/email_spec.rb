require 'spec_helper'

describe OpenIDConnect::Discovery::Principal::Email do
  subject { email }
  let(:email) { OpenIDConnect::Discovery::Principal::Email.new identifier }
  let(:identifier) { 'nov@server.example.com' }

  its(:identifier) { should == identifier }
  its(:host) { should == 'server.example.com' }
end