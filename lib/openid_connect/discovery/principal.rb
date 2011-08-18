module OpenIDConnect
  module Discovery
    class Principal
      attr_reader :identifier, :host
      delegate :discover!, :to => :identifier

      def initialize(identifier)
        raise InvalidIdentifier if identifier.blank?
        @identifier = case identifier
        when /^(=|@|!)/
          XRI.new(identifier)
        when /@/
          Email.new(identifier)
        else
          URI.new(identifier)
        end
      end
    end
  end
end