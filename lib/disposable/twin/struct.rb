module Disposable
  class Twin
    # Twin that uses a hash to populate.
    #
    #   Twin.new(id: 1)
    module Struct
      # Structs use from_hash as they can simply consume the incoming hash.
      def initialize(model, options={})
        @model = model

        @fields = {}

        self.class.representer(:setup) do |dfn|
          dfn.merge!(
            :representable => false, # don't call #to_hash, only prepare.
            :instance       => lambda { |model, args|

              puts "building #{args.binding[:twin].evaluate(nil)} with #{model.inspect}"

              args.binding[:twin].evaluate(nil).new(model) }, # wrap nested properties in form.

              prepare:  lambda { |obj, *| obj } # don't extend the object with module from :extend (why is that?)
          )
        end.new(self).from_hash(model)



        return



        super # call from_hash(options) # FIXME: this is wrong and already calls from_hash(options)

        #puts "@@@@@@ merge #{model.inspect} in #{self}"
        from_hash(model.merge(options))
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