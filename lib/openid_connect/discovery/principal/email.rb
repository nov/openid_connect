module OpenIDConnect
  module Discovery
    class Principal
      class Email < Principal
        def initialize(identifier)
          @identifier = identifier
          @host = identifier.split('@').last
        end

        def discover!
          
        end
      end
    end
  end
end