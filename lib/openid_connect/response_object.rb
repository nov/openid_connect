module OpenIDConnect
  class ResponseObject
    include AttrRequired, AttrOptional

    def initialize(attributes = {})
      (required_attributes + optional_attributes).each do |_attr_|
        self.send :"#{_attr_}=", attributes[_attr_]
      end
      attr_missing!
    end

    def as_json
      (required_attributes + optional_attributes).inject({}) do |hash, _attr_|
        hash.merge! _attr_ => self.send(_attr_)
      end.delete_if do |key, value|
        value.nil?
      end
    end
  end
end

Dir[File.dirname(__FILE__) + '/response_object/*.rb'].each do |file|
  require file
end