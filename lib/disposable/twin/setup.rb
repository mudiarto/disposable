module Disposable::Twin::Setup
  def initialize(model, options={})
    @model  = model
    @fields = setup_representer.new(model).to_hash # TODO: options!
  end

private
  def setup_representer
    self.class.representer(:setup) do |dfn|
      dfn.merge!(
        representable: false, # don't call #to_hash, only prepare.
        prepare:       lambda { |model, args| args.binding[:extend].evaluate(nil).new(model) }, # wrap nested properties in twin.
      )
    end
  end
end