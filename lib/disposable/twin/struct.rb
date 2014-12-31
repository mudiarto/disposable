module Disposable
  class Twin
    # Twin that uses a hash to populate.
    #
    #   Twin.new(id: 1)
    module Struct
      def initialize(model, options={})
        super # call from_hash(options) # FIXME: this is wrong and already calls from_hash(options)

        from_hash(model.merge(options))
      end


      module Sync
        def sync
          model.replace self.class.representer_class.new(self).to_hash
        end
      end

      include Sync
    end
  end
end