module Disposable
  class Twin
    class Decorator < Representable::Decorator
      include Representable::Hash
      include AllowSymbols

      # DISCUSS: same in reform, is that a bug in represntable?
      def self.clone # called in inheritable_attr :representer_class.
        Class.new(self) # By subclassing, representable_attrs.clone is called.
      end

      def self.build_config
        Config.new(Definition)
      end

      def twin_names
        representable_attrs.
          find_all { |attr| attr[:twin] }.
          collect { |attr| attr.name.to_sym }
      end

      # TODO: merge with reform.
      def self.each(only_twin=true, &block)
        definitions = representable_attrs
        definitions = representable_attrs.find_all { |attr| attr[:twin] } if only_twin

        definitions.each(&block)
        self
      end


      def self.default_inline_class
        Twin
      end
      # Inline forms always get saved in :extend.
      def self.build_inline(base, features, name, options, &block)
        # features = options[:features]

        Class.new(base || default_inline_class) do
          # include *features

          class_eval &block
        end
      end
    end


    class Definition < Representable::Definition
      def dynamic_options
        super + [:twin]
      end
    end
  end
end