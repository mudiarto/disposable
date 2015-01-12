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
          puts "~~~~#{preferences.to_hash}"
          return {"recorded" => recorded, "released"=>released, "preferences" => preferences.to_hash}


          representer = self.class.representer_class.new(self)

          puts "======+++++= sync in Struct: #{representer.to_hash.inspect}"
          model.replace self.class.representer_class.new(self).to_hash
        end
      end
      include Sync


      def to_hash
        # reuse setup representer for rendering hash.
        self.class.representer(:setup).new(self).to_hash
      end
    end
  end
end