require 'spec_helper'

describe OpenIDConnect::Debugger::RequestFilter do
  let(:resource_endpoint) { 'https://example.com/resources' }
  let(:request) { HTTP::Message.new_request(:get, URI.parse(resource_endpoint)) }
  let(:response) { HTTP::Message.new_response({:hello => 'world'}.to_json) }
  let(:request_filter) { OpenIDConnect::Debugger::RequestFilter.new }

  describe '#filter_request' do
    it 'should log request' do
      OpenIDConnect.logger.should_receive(:info).with(
        "======= [OpenIDConnect] HTTP REQUEST STARTED =======\n" +
        request.dump
      )
      request_filter.filter_request(request)
    end
  end

  describe '#filter_response' do
    it 'should log response' do
      OpenIDConnect.logger.should_receive(:info).with(
        "--------------------------------------------------\n" +
        response.dump +
        "\n======= [OpenIDConnect] HTTP REQUEST FINISHED ======="
      )
      request_filter.filter_response(request, response)
    end
  end
end