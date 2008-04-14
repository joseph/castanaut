module Castanaut

  # Castanaut uses compatibility layers to support automation on various
  # operating systems. Typically, each operating system will have one
  # compatibility file, though specific versions of the operating system
  # may need further compatibibility changes as well. Ultimately, it is
  # up to the Movie to identify the current operating system & make calls
  # to the appropriate compatibility layer.
  #
  # See the MacOsX, MacOsXTiger and MacOsXLeopard layers for examples.
  #
  module Compatibility
  end

end
