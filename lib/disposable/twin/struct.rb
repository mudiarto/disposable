module Disposable
  class Twin
    # Twin that uses a hash to populate.
    #
    #   Twin.new(id: 1, album: {title: "Matters"})
    module Struct
      # include Setup

      # Structs use from_hash as they can simply consume the incoming hash.
      def initialize(model, options={})
        @model  = model
        @fields = {}

        # we use a representer here to handle nested typed hashes. otherwise we could simply assign +model+ to @fields.
        # it goes through each property and assigns it via the setter to the twin. nested twins get instantiated, first.
        setup_representer.new(self).from_hash(model)
      end

      def setup_representer
        self.class.representer(:setup) do |dfn|
          dfn.merge!(
            prepare:  lambda { |model, args| model },
            instance: lambda { |model, args| args.binding[:extend].evaluate(nil).new(model) },
          )
        end
      end

      module Sync
        def sync
          # calls album.sync on nested properties.
          sync_representer.new(self).to_hash # compiles a nested hash that Twin will assign to the hash column property.
        end
      end
      include Sync
    end
  end
end