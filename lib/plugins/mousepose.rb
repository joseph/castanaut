module Castanaut; module Plugin

  # This module provides actions for controlling Mousepose, a commercial
  # application from Boinx Software. Basically it lets you put a halo around
  # the mouse whenever a key mouse action occurs.
  #
  # It doesn't do any configuration of Mousepose on the fly. Configure 
  # Mousepose settings before running your screenplay.
  #
  # Tested against Mousepose 2. More info: http://www.boinx.com/mousepose
  module Mousepose

    # Put a halo around the mouse. If a block is given to this method,
    # the halo will be turned off when the block completes. Otherwise,
    # you'll have to use dim to dismiss the halo.
    def highlight
      execute_applescript(%Q`
        tell application "Mousepose"
          start effect
        end
      `)
      if block_given?
        yield
        dim
      end
    end

    # Dismiss the halo around the mouse that was invoked by a previous
    # highlight method.
    def dim
      execute_applescript(%Q`
        tell application "Mousepose"
          stop effect
        end
      `)
    end
  end
end; end
