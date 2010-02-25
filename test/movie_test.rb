require File.dirname(__FILE__) + '/helper'

class MovieTest < Test::Unit::TestCase

  def test_truth
    assert true
  end


  def test_instantiate_movie
    assert Castanaut::Movie.new
  end


  def test_instantiate_movie_with_screenplay
    assert Castanaut::Movie.new(fixture_path('1.screenplay'))
  end

end
