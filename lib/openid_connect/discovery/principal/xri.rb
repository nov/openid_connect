module OpenIDConnect
  module Discovery
    class Principal
      class XRI < Principal
        def initialize(identifier)
          @identifier = identifier
        end
      end
    end
  end
end