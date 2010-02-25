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


    # Hit a command key combo toward the currently active application.
    #
    # Use any combination of "command", "option", "control", "shift".
    # ("command" is the default).
    #
    # Case matters! It's easiest to use lowercase, then "shift" if needed.
    #
    #   keystroke "t"                     # COMMAND-t
    #   keystroke "k", "control", "shift" # A combo
    #
    def keystroke(character, *special_keys)
      special_keys = ["command"] if special_keys.length == 0
      special_keys_as_applescript_array = special_keys.map { |k|
        "#{k} down"
      }.join(", ")
      execute_applescript(%Q'
        tell application "System Events"
          set frontApp to name of first item of (processes whose frontmost is true)
          tell application frontApp
            keystroke "#{character}" using {#{special_keys_as_applescript_array}}
          end
        end tell
      ')
    end


    # Click a menu item in any application. The name of the application
    # should be the first argument.
    #
    # Three dots will be automatically replaced by the appropriate ellipsis.
    #
    #   click_menu_item("TextMate", "Navigation", "Go to Symbol...")
    #
    # Based on menu_click, by Jacob Rus, September 2006:
    #   http://www.macosxhints.com/article.php?story=20060921045743404
    #
    def click_menu_item(*items)
      items_as_applescript_array = items.map { |i|
        %("#{i.gsub('...', "\342\200\246")}")
      }.join(", ")

      ascript = %Q`
        on menu_click(mList)
          local appName, topMenu, r
          if mList's length < 3 then error "Menu list is not long enough"

          set {appName, topMenu} to (items 1 through 2 of mList)
          set r to (items 3 through (mList's length) of mList)

          tell application "System Events" to my menu_click_recurse(r, ((process appName)'s (menu bar 1)'s (menu bar item topMenu)'s (menu topMenu)))
        end menu_click

        on menu_click_recurse(mList, parentObject)
        local f, r

        set f to item 1 of mList
        if mList's length > 1 then set r to (items 2 through (mList's length) of mList)

        tell application "System Events"
          if mList's length is 1 then
            click parentObject's menu item f
          else
            my menu_click_recurse(r, (parentObject's (menu item f)'s (menu f)))
          end if
        end tell
        end menu_click_recurse


        menu_click({#{items_as_applescript_array}})
      `
      execute_applescript(ascript)
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
