module Disposable
  class Twin
    # Twin that uses a hash to populate.
    #
    #   Twin.new(id: 1)
    module Struct
      def initialize(model, options={})
        super # call from_hash(options) # FIXME: this is wrong and already calls from_hash(options)

        #puts "@@@@@@ merge #{model.inspect} in #{self}"
        from_hash(model.merge(options))
      end


      module Sync
        def sync
          return {"recorded" => recorded, "released"=>released, "preferences" => preferences.to_hash}


          representer = self.class.representer_class.new(self)

          puts "======+++++= sync in Struct: #{representer.to_hash.inspect}"
          model.replace self.class.representer_class.new(self).to_hash
        end
      end
      include Sync


      def to_hash
        self.class.representer_class.new(self).to_hash
      end
    end
  end
end