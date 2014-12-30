require 'test_helper'
require "representable/debug"

require 'disposable/twin/struct'
class TwinStructTest < MiniTest::Spec
  class Song < Disposable::Twin
    include Struct
    property :number, default: 1 # FIXME: this should be :default_if_nil so it becomes clear with a model.
    option   :cool?
  end

  # empty hash
  it { Song.new({}).number.must_equal 1 }
  # model hash
  it { Song.new(number: 2).number.must_equal 2 }

  # with hash and options as one hash.
  it { Song.new(number: 3, cool?: true).cool?.must_equal true }
  it { Song.new(number: 3, cool?: true).number.must_equal 3 }

  # with model hash and options hash separated.
  it { Song.new({number: 3}, {cool?: true}).cool?.must_equal true }
  it { Song.new({number: 3}, {cool?: true}).number.must_equal 3 }


  describe "writing" do
    let (:song) { Song.new(model, {cool?: true}) }
    let (:model) { {number: 3} }

    # writer
    it do
      song.number = 9
      song.number.must_equal 9
      model[:number].must_equal 3
    end

    # writer with sync
    it do
      song.extend(Disposable::Twin::Struct::Sync)
      song.number = 9
      song.sync

      song.number.must_equal 9
      model["number"].must_equal 9

      song.send(:model).object_id.must_equal model.object_id
    end
  end

end


# Non-lazy initialization. This will copy all properties from the wrapped object to the twin when
# instantiating the twin.
module NonLazyy
  def initialize(model, options={})
    @fields = self.class.representer_class.new(model).to_hash # TODO: options!
  end
end

class TwinWithNestedStructTest < MiniTest::Spec
  class Song < Disposable::Twin
    include NonLazyy
    property :title

    class HH < Disposable::Twin
      include Struct
      property :recorded
      property :released
    end

    property :options, prepare: lambda { |model, *args| HH.new(model) },
      # instance: lambda { |fragment, *| fragment },
      representable: false do # don't call #to_hash, this is triggered in the twin's constructor.


      # property :recorded
      # property :released
    end

  end

  let (:model) { OpenStruct.new(title: "Seed of Fear and Anger", options: {recorded: true}) }

  it("xxx") { Song.new(model).options.recorded.must_equal true }
  it {
  song = Song.new(model)
    song.options.recorded = "yo"
    song.options.recorded.must_equal "yo"

    # song.extend(Disposable::Twin::Struct::Sync)
    # song.sync

    model.title.must_equal "Seed of Fear and Anger"
    model.options[:recorded].must_equal "yo"
     }
end