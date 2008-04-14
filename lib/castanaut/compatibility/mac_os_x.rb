module Castanaut; module Compatibility

  # This class provides some default methods that should work on all
  # Mac OS X based systems, regardless of the exact version of your OS.
  #
  class MacOsX

    # Returns true if the computer should use this compatibility layer.
    # Always returns false for MacOsX because this is a generic compatibility
    # layer that shouldn't be used on it's own.
    #
    def self.version_check
      false
    end

    def initialize(movie)
      raise ArgumentError.new("First argument must be a Castanaut::Movie") unless movie.is_a?(Castanaut::Movie)
      @movie = movie
    end

    # See Movie#launch for documentation.
    #
    # The method will also look for application-specific commands for
    # ensuring that a window is open & positioning that window.
    # These methods should be named +ensure_window_for_app_name+
    # and +positioning_for_app_name+ respectively. So, if you launch
    # the "Address Book" application, the +ensure_window_for_address_book+
    # and +positioning_for_address_book+ methods will be used.
    #
    # See Plugin::Safari#ensure_window_for_safari for an example.
    #
    def launch(app_name, options)
      ensure_window = nil
      begin
        ensure_window = movie.send("ensure_window_for_#{ app_name.downcase }")
      rescue
      end
      ensure_window ||= ""

      positioning = nil
      begin
        positioning = movie.send("positioning_for_#{ app_name.downcase }")
      rescue
      end
      unless positioning
        if options[:to]
          pos = "#{options[:to][:left]}, #{options[:to][:top]}"
          dims = "#{options[:to][:left] + options[:to][:width]}, " +
            "#{options[:to][:top] + options[:to][:height]}"
          if options[:to][:width]
            positioning = "set bounds of front window to {#{pos}, #{dims}}"
          else
            positioning = "set position of front window to {#{pos}}"
          end
        end
      end

      execute_applescript(%Q`
        tell application "#{app_name}"
          activate
          #{ensure_window}
          #{positioning}
        end tell
      `)
    end
    
    # Use MacOS's native text-to-speech functionality to emulate a human
    # voice saying the narrative text.
    #
    def say(narrative)
      run(%Q`say "#{escape_dq(narrative)}"`)
    end
    
    # Returns a region hash describing the entire screen area.
    # (May be wonky for multi-monitor set-ups.)
    #
    def screen_size
      coords = execute_applescript(%Q`
        tell application "Finder"
            get bounds of window of desktop
        end tell
      `)
      coords = coords.split(", ").collect {|c| c.to_i}
      movie.to(*coords)
    end
    
    # Runs an applescript from a string.
    # Returns the result.
    #
    def execute_applescript(scpt)
      File.open(FILE_APPLESCRIPT, 'w') {|f| f.write(scpt)}
      result = run("osascript #{FILE_APPLESCRIPT}")
      File.unlink(FILE_APPLESCRIPT)
      result
    end
    
    private
    # Returns the current movie instance.
    #
    def movie
      @movie
    end
    
    # The following methods are purely for convenience & simply call
    # the appropriate method in the movie class.
    #
    def run(cmd)
      movie.run(cmd)
    end
    
    def escape_dq(str)
      movie.send :escape_dq, str
    end
    
    def not_supported(msg)
      movie.send :not_supported, msg
    end
    
  end
  
end; end