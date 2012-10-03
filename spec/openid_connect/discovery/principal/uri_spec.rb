require 'spec_helper'

describe OpenIDConnect::Discovery::Principal::URI do
  subject { uri }
  let(:uri) { OpenIDConnect::Discovery::Principal::URI.new identifier }

  {
    'server.example.com' => 'https://server.example.com',
    'server.example.com/' => 'https://server.example.com/',
    'server.example.com/nov' => 'https://server.example.com/nov',
    'server.example.com/nov/' => 'https://server.example.com/nov/',
    'server.example.com/nov#id' => 'https://server.example.com/nov',
    'server.example.com/nov?k=v' => 'https://server.example.com/nov?k=v',
    'server.example.com/nov?k=v#id' => 'https://server.example.com/nov?k=v',
    'http://server.example.com' => 'http://server.example.com',
    'http://server.example.com/' => 'http://server.example.com/',
    'http://server.example.com/nov' => 'http://server.example.com/nov',
    'http://server.example.com/nov/' => 'http://server.example.com/nov/',
    'http://server.example.com/nov#id' => 'http://server.example.com/nov',
    'http://server.example.com/nov?k=v' => 'http://server.example.com/nov?k=v',
    'http://server.example.com/nov?k=v#id' => 'http://server.example.com/nov?k=v',
    'https://server.example.com' => 'https://server.example.com',
    'https://server.example.com/' => 'https://server.example.com/',
    'https://server.example.com/nov' => 'https://server.example.com/nov',
    'https://server.example.com/nov/' => 'https://server.example.com/nov/',
    'https://server.example.com/nov#id' => 'https://server.example.com/nov',
    'https://server.example.com/nov?k=v' => 'https://server.example.com/nov?k=v',
    'https://server.example.com/nov?k=v#id' => 'https://server.example.com/nov?k=v',
  }.each do |input, output|
    context "when '#{input}' is given" do
      let(:identifier) { input }
      its(:identifier) { should == output }
      its(:host) { should == 'server.example.com' }
      its(:port) { should be_nil }
    end
  end

  {
    'server.example.com:8080' => 'https://server.example.com:8080'
  }.each do |input, output|
    context "when '#{input}' is given" do
      let(:identifier) { input }
      its(:identifier) { should == output }
      its(:host) { should == 'server.example.com' }
      its(:port) { should == 8080 }
    end
  end

  describe 'error handling' do
    let(:identifier) { '**' }
    it do
      expect { uri }.to raise_error OpenIDConnect::Discovery::InvalidIdentifier
    end
  end
end