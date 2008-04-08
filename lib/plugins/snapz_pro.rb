module Castanaut
  
  module Plugin

    # This module provides primitive support for Snapz Pro, a screencast capturing
    # tool for Mac OS X from Abrosia Software.
    #
    # Unfortunately Snapz Pro has virtually no AppleScript support so for this plugin
    # to work correctly you must do the following.
    #
    # 1) Invoke Snapz Pro.
    # 2) Position the initial window so that it is flush with the left side of the
    #    screen & the top of the window is flush with the bottom of the menu-bar.
    #    The window's close button will be below & slightly to the left of the
    #    Apple menu.
    # 3) Click the "Movie..." button & set everything up just the way you want it.
    # 4) Close all Snapz Pro windows & run your castanaut script as usual :-)
    #
    # Once your script has finished you'll have to tell Snapz how & where to save
    # the captured movie manually.
    #
    # More info: http://www.ambrosiasw.com/utilities/snapzprox/
    module SnapzPro

      # Tell Snapz to start recording. Will automatically stop recording when
      # the movie is ended, unless you set :auto_stop => false in options.
      def snapz_start_recording(options = {})
        snapz_invoke

        # Click the "Movie..." button
        move to(332, 130)
        click

        # Start recording
        hit Castanaut::Enter

        unless options[:auto_stop] == false
          at_end_of_movie { snapz_stop_recording }
        end
      end

      # Tell Snapz to stop recording (by invoking it again).
      def snapz_stop_recording
        snapz_invoke
      end

      private
      # Invoke Snapz Pro. Bascially the same thing as hitting the keyboard shortcut.
      def snapz_invoke
        execute_applescript(%Q`
          tell application "Snapz Pro X"
          	invoke
          end tell
        `)
      end
    end
  end
end
