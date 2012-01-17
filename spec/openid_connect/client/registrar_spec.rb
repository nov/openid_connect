require 'spec_helper'

describe OpenIDConnect::Client::Registrar do
  subject { instance }
  let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint, attributes) }
  let(:endpoint) { 'https://server.example.com/clients' }

  context 'when endpoint given' do
    context 'when attributes given' do
      context 'when type=client_associate' do
        let(:attributes) do
          {
            :type => :client_associate
          }
        end
        it { should be_valid }
      end

      context 'when type=client_update' do
        context 'when client_id given' do
          let(:attributes) do
            {
              :type => :client_update,
              :client_id => 'client.example.com'
            }
          end
          it { should be_valid }
        end

        context 'otherwise' do
          let(:attributes) do
            {
              :type => :client_update
            }
          end
          it { should_not be_valid }
        end
      end

      context 'otherwise' do
        let(:attributes) do
          {
            :type => :invalid_type
          }
        end
        it { should_not be_valid }
      end
    end

    context 'otherwise' do
      let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint) }
      it do
        expect do
          instance
        end.should_not raise_error
      end
      it { should_not be_valid }
    end
  end

  context 'otherwise' do
    let(:instance) { OpenIDConnect::Client::Registrar.new(endpoint) }
    let(:endpoint) { '' }

    it do
      expect do
        instance
      end.should raise_error AttrRequired::AttrMissing
    end
  end

  describe '#associate!' do
    it :TODO
  end

  describe '#update!' do
    it :TODO
  end

  describe '#as_json' do
    it :TODO
  end

  describe '#validate!' do
    context 'when valid' do
      let(:attributes) do
        {
          :type => :client_associate
        }
      end
      it do
        expect do
          instance.validate!
        end.should_not raise_error OpenIDConnect::ValidationFailed
      end
    end

    context 'otherwise' do
      let(:attributes) do
        {
          :type => :client_update
        }
      end
      it do
        expect do
          instance.validate!
        end.should raise_error OpenIDConnect::ValidationFailed
      end
    end
  end
end