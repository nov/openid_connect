module OpenIDConnect
  class RequestObject
    module Claimable
      def self.included(klass)
        klass.send :attr_optional, :claims
        klass.send :alias_method_chain, :initialize, :claims
        klass.send :alias_method_chain, :as_json, :keep_blank
      end

      def initialize_with_claims(attributes = {})
        initialize_without_claims attributes
        if claims.present?
          _claims_ = {}
          claims.each do |key, value|
            _claims_[key] = case value
            when :optional, :voluntary
              {
                essential: false
              }
            when :required, :essential
              {
                essential: true
              }
            else
              value
            end
          end
          self.claims = _claims_.with_indifferent_access
        end
      end

      def as_json_with_keep_blank(options = {})
        keys = claims.try(:keys)
        hash = as_json_without_keep_blank options
        Array(keys).each do |key|
          hash[:claims][key] ||= nil
        end
        hash
      end

      def required?(claim)
        accessible?(claim) && claims[claim].is_a?(Hash) && claims[claim][:essential]
      end
      alias_method :essential?, :required?

      def optional?(claim)
        accessible?(claim) && !required?(claim)
      end
      alias_method :voluntary?, :optional?

      def accessible?(claim)
        claims.try(:include?, claim)
      end
    end
  end
end