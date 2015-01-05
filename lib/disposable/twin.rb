require 'uber/inheritable_attr'
require 'representable/decorator'
require 'representable/hash'
require 'disposable/twin/representer'
require 'disposable/twin/option'
require 'disposable/twin/builder'

# Twin.new(model/composition hash/hash, options)
#   assign hash to @fields
#   write: write to @fields
#   sync/save is the only way to write back to the model.


# twin.write(title: "Poy", options: {published: true}) => assign and sync!

module Disposable
  class Twin
    extend Uber::InheritableAttr
    inheritable_attr :representer_class
    self.representer_class = Class.new(Decorator)


    def self.property(name, options={}, &block)
      deprecate_as!(options) # TODO: remove me in 0.1.0
      options[:private_name] = options.delete(:from) || name
      options[:pass_options] = true

      representer_class.property(name, options, &block).tap do |definition|
        mod = Module.new do
          define_method(name)       { read_property(name, options[:private_name]) }
          define_method("#{name}=") { |value| write_property(name, options[:private_name], value) } # TODO: this is more like prototyping.
        end
        include mod
      end
    end

    def self.collection(name, options={}, &block)
      property(name, options.merge(:collection => true), &block)
    end


    module Initialize
      def initialize(model, options={})
        @fields = {}
        @model  = model

        from_hash(options) # assigns known properties from options.
      end
    end
    include Initialize


    # read/write to twin using twin's API (e.g. #record= not #album=).
    def self.write_representer
      representer = Class.new(representer_class) # inherit configuration
    end

  private
    def read_property(name, private_name)
      return @fields[name.to_s] if @fields.has_key?(name.to_s)
      @fields[name.to_s] = read_from_model(private_name)
    end

    def read_from_model(getter)
      model.send(getter)
    end

    def write_property(name, private_name, value)
       @fields[name.to_s] = value
    end

    def from_hash(options)
      self.class.write_representer.new(self).from_hash(options)
    end

    attr_reader :model # TODO: test

    include Option

    def self.deprecate_as!(options) # TODO: remove me in 0.1.0
      return unless as = options.delete(:as)
      options[:from] = as
      warn "[Disposable] The :as options got renamed to :from."
    end


    module Sync
      def sync
        # call sync on all nested twins, as we do it in reform.
        model.title = title

        #options.preferences.sync # fixme, of course.

        # puts
        # puts options.inspect
        model.options = options.sync # this is kinda wrong, as that should all happen in one db transaction? model.update_attributes()

      end

    private
      def sync!(options) # semi-public.

        input = sync_hash(options)
        # if aliased_model was a proper Twin, we could do changed? stuff there.

        options.delete(:exclude) # TODO: can we use 2 options?

        dynamic_sync_representer.new(aliased_model).from_hash(input, options) # sync properties to Song.

        model
      end

      def input_representer
        self.class.representer(:input, :all => true) do |dfn|
          if dfn[:form]
            dfn.merge!(
              :representable  => false,
              :prepare        => lambda { |obj, *| obj },
            )
          else
            dfn.merge!(:render_nil => true) # do sync nil values back to the model for scalars.
          end
        end
      end

      # Writes input to model.
      def sync_representer
        self.class.representer(:sync, :all => true) do |dfn|
          if dfn[:form]
            dfn.merge!(
              :instance     => lambda { |fragment, *| fragment }, # use model's nested property for syncing.
                # FIXME: do we allow options for #sync for nested forms?
              :deserialize => lambda { |object, *| model = object.sync!({}) } # sync! returns the synced model.
              # representable's :setter will do collection=([..]) or property=(..) for us on the model.
            )
          end
        end
      end

      def self.representers # keeps all transformation representers for one class.
        @representers ||= {}
      end

      def self.representer(name=nil, options={}, &block)
        return representer_class.each(&block) if name == nil
        return representers[name] if representers[name] # don't run block as this representer is already setup for this form class.

        only_forms = options[:all] ? false : true
        base       = options[:superclass] || representer_class

        representers[name] = Class.new(base).each(only_forms, &block) # let user modify representer.
      end


    end
    include Sync
  end
end