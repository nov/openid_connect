require 'spec_helper'

describe OpenIDConnect::ResponseObject do
  class OpenIDConnect::ResponseObject::SubClass < OpenIDConnect::ResponseObject
    attr_required :required
    attr_optional :optional
  end

  let(:klass) { OpenIDConnect::ResponseObject::SubClass }
  subject { klass.new attributes }

  context 'when required attributes are given' do
    context 'when optional attributes are given' do
      let :attributes do
        {:required => 'Required', :optional => 'Optional'}
      end
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
    let :attributes do
      {:required => 'Required', :optional => 'Optional'}
    end
    its(:as_json) do
      should == {:required => 'Required', :optional => 'Optional'}
    end
  end
end
