require 'test/unit'
require 'lib/castanaut'


def fixture_path(path)
  File.join(File.dirname(__FILE__), 'fixtures', path)
end


def fixture(path)
  IO.read(fixture_path(path))
end
