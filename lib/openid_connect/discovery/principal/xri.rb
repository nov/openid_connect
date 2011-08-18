module OpenIDConnect
  module Discovery
    class Principal
      class XRI < Principal
        def initialize(identifier)
          @identifier = identifier
        end

        def discover!
          
        end
      end
    end
  end
end