# Callback is designed to work with twins under the hood since twins track events
# like "adding" or "deleted". However, it could run with other model layers, too.
# For example, when you manage to make ActiveRecord track those events, you won't need a
# twin layer underneath.
module Disposable::Twin::Callback
  class Dispatch
    def initialize(twins)
      @twins = twins.is_a?(Array) ? twins : [twins] # TODO: find that out with Collection.
    end

    def on_add(state=nil) # how to call it once, for "all"?
      # @twins can only be Collection instance.
      @twins.added.each do |item|
        yield item if state.nil?
        yield item if item.created? && state == :created # :created # DISCUSS: should we really keep that?
      end
    end

    def on_delete
      # @twins can only be Collection instance.
      @twins.deleted.each do |item|
        yield item
      end
    end

    def on_destroy
      @twins.destroyed.each do |item|
        yield item
      end
    end

    def on_update
      @twins.each do |twin|
        next if twin.created?
        next unless twin.persisted? # only persisted can be updated.
        next unless twin.changed?
        yield twin
      end
    end

    def on_create
      @twins.each do |twin|
        next unless twin.created?
        yield twin
      end
    end
  end
end