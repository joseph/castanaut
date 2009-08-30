module Castanaut

  module Plugin
    # This module provides actions for controlling Terminal.app
    # Terminal 2.0.1 on Mac OS X 10.5.6
    module Terminal

      # applescript fragment for new windows. i use terminal to edit the code so I always want a new window instance
      def ensure_window_for_terminal
        # "if (count(windows)) < 1 then make new document"
        do_script
      end

      def do_script(args = '')
        "do script \"#{args}\""
      end

      def launch_terminal
        launch "Terminal"
        execute_applescript ensure_window_for_terminal
      end

      def run_in_terminal(cmd)
        execute_applescript "
          tell application \"Terminal\"
            #{do_script(cmd)} in window 1
          end tell"
      end

      # Open a URL in the front Safari tab.
      # def url(str)
      #   execute_applescript(%Q`
      #     tell application "safari" 
      #       do JavaScript "location.href = '#{str}'" in front document 
      #     end tell
      #   `)
      # end

      def cli(cmd)
        type cmd
      end

      def type_pre(string)
        type string.gsub(/\n/, '')
      end

      def vim_insert(string)
        type_pre 'i' + string + ''
      end

    end
  end 

  module Exceptions
  end

end
