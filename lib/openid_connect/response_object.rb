module OpenIDConnect
  class ResponseObject
    include ActiveModel::Validations, AttrRequired, AttrOptional

    class ValidationFailed < Exception
      attr_reader :errors

      def initialize(errors)
        super errors.full_messages.to_sentence
        @errors = errors
      end
    end

    def initialize(attributes = {})
      all_attributes.each do |_attr_|
        self.send :"#{_attr_}=", attributes[_attr_]
      end
      attr_missing!
    end

    def all_attributes
      required_attributes + optional_attributes
    end

    def require_at_least_one_attributes
      all_blank = all_attributes.all? do |key|
        self.send(key).blank?
      end
      errors.add :base, 'At least one attribute is required' if all_blank
    end

    def as_json(options = {})
      options ||= {} # options can be nil when to_json is called without options
      validate! unless options[:skip_validation]
      all_attributes.inject({}) do |hash, _attr_|
        value = self.send(_attr_)
        hash.merge! _attr_ => case value
        when ResponseObject
          value.as_json
        else
          value
        end
      end.delete_if do |key, value|
        value.nil?
      end
    end

    def validate!
      valid? or raise ValidationFailed.new(errors)
    end
  end
end

Dir[File.dirname(__FILE__) + '/response_object/*.rb'].each do |file|
  require file
end