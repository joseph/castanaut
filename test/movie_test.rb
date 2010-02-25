require File.dirname(__FILE__) + '/helper'

class MovieTest < Test::Unit::TestCase

  def test_truth
    assert(true)
  end


  def test_instantiate_movie
    assert(Castanaut::Movie.spawn.kind_of?(Castanaut::Movie))
  end


  def test_absolute_mouse_movement
    mov = Castanaut::Movie.spawn

    mov.move(mov.to(100, 100))
    mloc = mov.cursor_location
    assert((99..101).to_a.include?(mloc[:x]))
    assert((99..101).to_a.include?(mloc[:y]))
  end


  def test_relative_mouse_movement
    mov = Castanaut::Movie.spawn

    mloc = mov.cursor_location
    mov.move(mov.by(100, 100))

    new_mloc = mov.cursor_location
    assert_equal(new_mloc[:x], mloc[:x] + 100)
    assert_equal(new_mloc[:y], mloc[:y] + 100)
  end


  def test_plugin_extensibility
    mov = Castanaut::Movie.spawn
    assert(!mov.respond_to?(:to_element))
    mov.plugin('safari')
    assert(mov.respond_to?(:to_element))
  end


  def test_perform_and_skip
    mov = Castanaut::Movie.spawn

    x = 1
    mov.perform("Something") {
      x = 3
      mov.skip
      x = 4
    }
    assert_equal(3, x)
  end


  def test_credits
    mov = Castanaut::Movie.spawn
    x = 1
    mov.at_end_of_movie { x = 3 }
    assert_equal(1, x)
    mov.send(:roll_credits)
    assert_equal(3, x)
  end

end
