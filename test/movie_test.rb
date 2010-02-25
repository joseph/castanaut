require File.dirname(__FILE__) + '/helper'

class MovieTest < Test::Unit::TestCase

  def test_truth
    assert(true)
  end


  def test_instantiate_movie
    assert(Castanaut::Movie.spawn.kind_of?(Castanaut::Movie))
  end


  def test_instantiate_movie_with_screenplay
    assert(
      Castanaut::Main.run([fixture_path('1.screenplay')]).kind_of?(Castanaut::Movie)
    )
  end


  def test_absolute_mouse_movement
    mov = Castanaut::Movie.spawn

    mov.move(mov.to(100, 100))
    mloc = mov.cursor_location
    assert_equal(100, mloc[:x])
    assert_equal(100, mloc[:y])
  end


  def test_relative_mouse_movement
    mov = Castanaut::Movie.spawn

    mloc = mov.cursor_location
    mov.move(mov.by(100, 100))

    new_mloc = mov.cursor_location
    assert_equal(new_mloc[:x], mloc[:x] + 100)
    assert_equal(new_mloc[:y], mloc[:y] + 100)
  end

end
