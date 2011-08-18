require 'spec_helper'

describe OpenIDConnect::ResponseObject do
  class OpenIDConnect::ResponseObject::SubClass < OpenIDConnect::ResponseObject
    attr_required :required
    attr_optional :optional
    validates :required, :inclusion => {:in => ['Required', 'required']}, :length => 1..10
  end

  subject { klass.new attributes }
  let(:klass) { OpenIDConnect::ResponseObject::SubClass }
  let :attributes do
    {:required => 'Required', :optional => 'Optional'}
  end

  context 'when required attributes are given' do
    context 'when optional attributes are given' do
      its(:required) { should == 'Required' }
      its(:optional) { should == 'Optional' }
    end

    context 'otherwise' do
      let :attributes do
        {:required => 'Required'}
      end
      its(:required) { should == 'Required' }
      its(:optional) { should == nil }
    end
  end

  context 'otherwise' do
    context 'when optional attributes are given' do
      let :attributes do
        {:optional => 'Optional'}
      end
      it do
        expect { klass.new attributes }.should raise_error AttrRequired::AttrMissing
      end
    end

    context 'otherwise' do
      it do
        expect { klass.new }.should raise_error AttrRequired::AttrMissing
      end
    end
  end

  describe '#as_json' do
    its(:as_json) do
      should == {:required => 'Required', :optional => 'Optional'}
    end
  end

  describe '#validate!' do
    let(:invalid) do
      instance = klass.new attributes
      instance.required = 'Out of List and Too Long'
      instance
    end

    it 'should raise OpenIDConnect::ResponseObject::ValidationFailed with ActiveModel::Errors' do
      expect { invalid.validate! }.should raise_error(OpenIDConnect::ResponseObject::ValidationFailed) { |e|
        e.message.should == 'Required is not included in the list and Required is too long (maximum is 10 characters)'
        e.errors.should be_a ActiveModel::Errors
      }
    end
  end
end
