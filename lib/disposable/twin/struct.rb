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


      module ToH
        def to_hash
          {"show_image" => show_image, "play_teaser" => play_teaser}
        end
      end
      module Sync
        def sync
          puts "preferences: #{preferences.to_hash.inspect}"
          preferences.extend(ToH)

          return {"recorded" => recorded, "released"=>released, "preferences" => preferences.to_hash}


          require "representable/debug"
          representer = self.class.representer_class.new(self)

          puts "======+++++= sync in Struct: #{representer.to_hash.inspect}"
          model.replace self.class.representer_class.new(self).to_hash
        end
      end

      include Sync
    end
  end
end