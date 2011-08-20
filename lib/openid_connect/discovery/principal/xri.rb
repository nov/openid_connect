module OpenIDConnect
  module Discovery
    class Principal
      class XRI < Principal
        def initialize(identifier)
          @identifier = identifier
        end

        def discover!(cache_options = {})
          raise NotImplementedError.new('XRI is not supported yet')
        end
      end
    end
  end
end