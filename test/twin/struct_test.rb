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
    @model = model
    @fields = self.class.representer_class.new(model).to_hash # TODO: options!
  end
end

class TwinWithNestedStructTest < MiniTest::Spec
  class Song < Disposable::Twin
    include NonLazyy
    property :title

    class Preferences < Disposable::Twin
      include Struct
      property :show_image
      property :play_teaser
    end

    class HH < Disposable::Twin
      include Struct
      property :recorded
      property :released

      property :preferences,
        instance: lambda { |value, *| Preferences.new(value) },
        prepare:  lambda { |obj, *| obj } do # don't extend the object with module from :extend (why is that?)
      end
    end




    property :options, prepare: lambda { |model, *args| HH.new(model) },
      # instance: lambda { |fragment, *| fragment },
      representable: false do # don't call #to_hash, this is triggered in the twin's constructor.


      # property :recorded
      # property :released
    end

    # TODO: hash in hash!

  end

  # FIXME: test with missing hash properties, e.g. without released and with released:false.
  let (:model) { OpenStruct.new(title: "Seed of Fear and Anger", options: {recorded: true, released: 1,
    preferences: {show_image: true, play_teaser: 2}}) }

  # public "hash" reader
  it { Song.new(model).options.recorded.must_equal true }

  # public "hash" writer
  it ("xxx") {
    song = Song.new(model)

    # puts song.options.inspect
    puts song.options.preferences.to_hash
    # raise

    song.options.recorded = "yo"
    song.options.recorded.must_equal "yo"

    song.options.preferences.show_image.must_equal true
    song.options.preferences.play_teaser.must_equal 2

    song.options.preferences.show_image= 9


    # song.extend(Disposable::Twin::Struct::Sync)
    song.sync # this is only called on the top model, e.g. in Reform#save.

    model.title.must_equal "Seed of Fear and Anger"
    model.options["recorded"].must_equal "yo"
    model.options["preferences"].must_equal({"show_image" => 9, "play_teaser"=>2})
     }
end



# reform
#   sync: twin.title = "Good Bye"
#         album.sync (copy attributes in nested form)
#           twin.name = "Matters"
#   save: twin.save (this will do twin.sync... does that call save on all nested twins, too, or do we still have to do that in reform?)