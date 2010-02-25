module Castanaut; module OS; module MacOSX

  # This class is intended to work on machines running Mac OS X 10.5.x or
  # greater.
  #
  # KNOWN LIMITATIONS
  #
  #   Partially working:
  #   * type - does not support the :speed option
  #   * hit - only works with special keys (those in keys.rb) not
  #     other characters (like 'a'), and does not support modifier keys
  #     (you can use keystroke instead, perhaps)
  #
  class Movie < Castanaut::Movie

    register("Mac OS X 10.5 or greater")


    # Returns true if the current platform is Mac OS X 10.5 or greater.
    #
    def self.platform_supported?
      vers = `/usr/bin/sw_vers -productVersion`.match(/10\.(\d)\.\d+/)
      vers[1].to_i >= 5
    rescue
      false
    end


    #--------------------------------------------------------------------------
    # KEYBOARD INPUT DIRECTIONS
    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    # Does not support modifiers (shift, ctrl, etc)
    def hit(key, *modifiers)
      not_supported "modifier keys for 'hit'"  unless modifiers.empty?
      automatically "hit #{key}"
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


    # If you pass :applescript => true, the AppleScript technique for typing
    # will be used. In this way you can use the :speed option —
    # it's not supported by the main (osxautomation) technique.
    #
    def type(str, opts = {})
      if opts.delete(:applescript)
        type_via_applescript(str, opts)
      else
        automatically "type #{str}"
      end
    end


    # The alternative typing method for Mac OS X - lets you set the
    # typomatic rate with the :speed option.
    #
    def type_via_applescript(str, opts = {})
      opts[:speed] = 50 unless !opts[:speed].nil?
      opts[:speed] = opts[:speed] / 1000.0

      full_str = ""
      str.split("").each do |a|
        a.gsub!(/"/, '\"')
        full_str += "delay #{opts[:speed]}\n" if !full_str.empty?
        full_str += "keystroke \"#{a}\"\n"
      end
      cmd = %Q'
          tell application "System Events"
            set frontApp to name of first item of (processes whose frontmost is true)
            tell application frontApp
              #{full_str}
            end
          end tell
      '
      execute_applescript cmd
      str
    end


    #---------------------------------------------------------------------------
    # MOUSE INPUT DIRECTIONS
    #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    def cursor(*options)
      options = combine_options(*options)

      apply_offset(options)
      @cursor_loc ||= {}
      @cursor_loc[:x] = options[:to][:left]
      @cursor_loc[:y] = options[:to][:top]

      automatically "mousemove #{@cursor_loc[:x]} #{@cursor_loc[:y]}"
    end

    alias :move :cursor


    def cursor_location
      loc = automatically("mouselocation").strip.split(' ')
      {:x => loc[0].to_i, :y => loc[1].to_i}
    end


    def click(btn = "left")
      automatically "mouseclick #{mouse_button_translate(btn)}"
    end


    def doubleclick(btn = "left")
      automatically "mousedoubleclick #{mouse_button_translate(btn)}"
    end


    def tripleclick(btn = "left")
      automatically "mousetripleclick #{mouse_button_translate(btn)}"
    end


    def mousedown(btn = "left")
      automatically "mousedown #{mouse_button_translate(btn)}"
    end


    def mouseup(btn = "left")
      automatically "mouseup #{mouse_button_translate(btn)}"
    end


    def drag(*options)
      options = combine_options(*options)
      apply_offset(options)
      automatically "mousedrag #{options[:to][:left]} #{options[:to][:top]}"
    end


    #--------------------------------------------------------------------------
    # WINDOWS AND APPLICATIONS DIRECTIONS
    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    # The method will also look for application-specific commands for
    # ensuring that a window is open & positioning that window.
    # These methods should be named +ensure_window_for_app_name+
    # and +positioning_for_app_name+ respectively. So, if you launch
    # the "Address Book" application, the +ensure_window_for_address_book+
    # and +positioning_for_address_book+ methods will be used.
    #
    # See Plugin::Safari#ensure_window_for_safari for an example.
    #
    def launch(app_name, *options)
      options = combine_options(*options)

      ensure_window = nil
      begin
        ensure_window = send("ensure_window_for_#{ app_name.downcase }")
      rescue
      end
      ensure_window ||= ""

      positioning = nil
      begin
        positioning = send("positioning_for_#{ app_name.downcase }")
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

    alias :activate :launch


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
      to(*coords)
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


    #--------------------------------------------------------------------------
    # USEFUL UTILITIES
    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    # Runs an applescript from a string.
    # Returns the result.
    #
    def execute_applescript(scpt)
      File.open(FILE_APPLESCRIPT, 'w') {|f| f.write(scpt)}
      result = run("osascript #{FILE_APPLESCRIPT}")
      File.unlink(FILE_APPLESCRIPT)
      result
    end


    # Use MacOS's native text-to-speech functionality to emulate a human
    # voice saying the narrative text.
    #
    def say(narrative)
      run(%Q`say "#{escape_dq(narrative)}"`)  unless ENV['SHHH']
    end


    protected

      def automatically(cmd)
        perms_test
        run("\"#{osxautomation_path}\" \"#{cmd}\"")
      end


    private

      def perms_test
        return if File.executable?(osxautomation_path)
        puts "IMPORTANT: Castanaut has recently been installed or updated. " +
          "You need to give it the right to control mouse and keyboard " +
          "input during screenplays."

        run("sudo chmod a+x #{osxautomation_path}")

        if File.executable?(osxautomation_path)
          puts "Permission granted. Thanks."
        else
          raise Castanaut::Exceptions::OSXAutomationPermissionError
        end
      end


      def osxautomation_path
        File.join(PATH, "cbin", "osxautomation")
      end


      def mouse_button_translate(btn)
        return btn if btn.is_a?(Integer)
        {"left" => 1, "right" => 2, "middle" => 3}[btn]
      end

  end

end; end; end
