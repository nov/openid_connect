require 'active_model'
require 'tzinfo'
require 'validate_url'
require 'validate_email'
require 'attr_required'
require 'attr_optional'

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
      validate!
      all_attributes.inject({}) do |hash, _attr_|
        hash.merge! _attr_ => self.send(_attr_)
      end.delete_if do |key, value|
        value.nil?
      end
    end

    def validate!
      raise ValidationFailed.new(errors) unless valid?
    end
  end
end

Dir[File.dirname(__FILE__) + '/response_object/*.rb'].each do |file|
  require file
end