module Castanaut

  # Castanaut uses plugins to extend the available actions beyond simple
  # mouse and keyboard input. Typically each plugin is application-specific.
  # See the Safari, Mousepose and Ishowu plugins for examples, and review the
  # README.txt for details on creating your own.
  #
  # In short, for a plugin called "foo", your script should have this structure:
  #
  #   module Castanaut
  #     module Plugin
  #       module Foo
  #
  #         # define your stage directions (ie, Movie instance methods) here.
  #
  #       end
  #     end
  #   end
  #
  # The script must exist in a sub-directory of the screenplay's location
  # called "plugins", and must be called (in this case): foo.rb.
  #
  module Plugin
  end

end
