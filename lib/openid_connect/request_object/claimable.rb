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
          claims.each do |key, value|
            case value
            when :optional
              claims[key] = {
                :optional => true
              }
            when :required
              claims[key] = nil
            end
          end
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
        accessible?(claim) && !optional?(claim)
      end

      def optional?(claim)
        accessible?(claim) && claims[claim].is_a?(Hash) && claims[claim][:optional]
      end

      def accessible?(claim)
        claims.try(:[], claim)
      end
    end
  end
end