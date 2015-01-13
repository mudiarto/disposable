require "test_helper"

class SetupTest < MiniTest::Spec
  module Model
    Song  = Struct.new(:id, :title, :album)
    Album = Struct.new(:id, :name, :songs)
  end

  class Song < Disposable::Twin
    include Setup # the problem here is, this will automatically include itself in sub representers. what if we don't want Setup in a particular nested twin?

    property :title

    property :album, twin: true do
      property :name

      collection :songs, twin: true do
        property :id
      end
    end
  end

  let (:model) { Model::Song.new(1, "Plastic", Model::Album.new(2, "Bad Mother Trucker", [Model::Song.new(3, "Giving Gravity A Hand")])) }
  subject { Song.new(model).instance_variable_get(:@fields) }

  it { subject["title"].must_equal "Plastic" }
  it { subject["album"].instance_variable_get(:@fields)["name"].must_equal "Bad Mother Trucker" }
  it { subject["album"].instance_variable_get(:@fields)["songs"][0].instance_variable_get(:@fields)["id"].must_equal 3 }
end