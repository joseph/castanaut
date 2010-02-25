require File.dirname(__FILE__) + '/helper'

class MainTest < Test::Unit::TestCase

  def test_instantiate_movie_with_screenplay
    assert(
      Castanaut::Main.run(
        [fixture_path('1.screenplay')]
      ).kind_of?(Castanaut::Movie)
    )
  end

end
