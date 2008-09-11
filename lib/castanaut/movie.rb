module Castanaut
  # The movie class is the containing context within which screenplays are 
  # invoked. It provides a number of basic stage directions for your 
  # screenplays, and can be extended with plugins.
  class Movie

    # Runs the "screenplay", which is a file containing Castanaut instructions.
    #
    def initialize(screenplay)
      perms_test

      if !screenplay || !File.exists?(screenplay)
        raise Castanaut::Exceptions::ScreenplayNotFound 
      end
      @screenplay_path = screenplay

      File.open(FILE_RUNNING, 'w') {|f| f.write('')}

      begin
        # We run the movie in a separate thread; in the main thread we 
        # continue to check the "running" file flag and kill the movie if 
        # it is removed.
        movie = Thread.new do
          begin
            eval(IO.read(@screenplay_path), binding)
          rescue => e
            @e = e
          ensure
            File.unlink(FILE_RUNNING) if File.exists?(FILE_RUNNING)
          end
        end

        while File.exists?(FILE_RUNNING)
          sleep 0.5
          break unless movie.alive?
        end

        if movie.alive?
          movie.kill
          raise Castanaut::Exceptions::AbortedByUser
        end

        raise @e if @e
      rescue => e
        puts "ABNORMAL EXIT: #{e.message}\n" + e.backtrace.join("\n")
      ensure
        roll_credits
        File.unlink(FILE_RUNNING) if File.exists?(FILE_RUNNING)
      end
    end

    # Launch the application matching the string given in the first argument.
    # (This resolution is handled by Applescript.)
    #
    # If the options hash is given, it should contain the co-ordinates for
    # the window (top, left, width, height). The to method will format these
    # co-ordinates appropriately.
    #
    def launch(app_name, *options)
      options = combine_options(*options)

      ensure_window = ""
      case app_name.downcase
        when "safari"
          ensure_window = "if (count(windows)) < 1 then make new document"
      end

      positioning = ""
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

      execute_applescript(%Q`
        tell application "#{app_name}"
          activate
          #{ensure_window}
          #{positioning}
        end tell
      `)
    end

    # Move the mouse cursor to the specified co-ordinates.
    #
    def cursor(*options)
      options = combine_options(*options)
      apply_offset(options)
      @cursor_loc ||= {}
      @cursor_loc[:x] = options[:to][:left]
      @cursor_loc[:y] = options[:to][:top]
      automatically "mousemove #{@cursor_loc[:x]} #{@cursor_loc[:y]}"
    end

    alias :move :cursor

    # Send a mouse-click at the current mouse location.
    #
    def click(btn = 'left')
      automatically "mouseclick #{mouse_button_translate(btn)}"
    end

    # Send a double-click at the current mouse location.
    #
    def doubleclick(btn = 'left')
      automatically "mousedoubleclick #{mouse_button_translate(btn)}"
    end
    
    # Send a triple-click at the current mouse location.
    # 
    def tripleclick(btn = 'left')
      automatically "mousetripleclick #{mouse_button_translate(btn)}"
    end

    # Press the button down at the current mouse location. Does not 
    # release the button until the mouseup method is invoked.
    #
    def mousedown(btn = 'left')
      automatically "mousedown #{mouse_button_translate(btn)}"
    end

    # Releases the mouse button pressed by a previous mousedown.
    #
    def mouseup(btn = 'left')
      automatically "mouseup #{mouse_button_translate(btn)}"
    end

    # "Drags" the mouse by (effectively) issuing a mousedown at the current 
    # mouse location, then moving the mouse to the specified coordinates, then
    # issuing a mouseup.
    #
    def drag(*options)
      options = combine_options(*options)
      apply_offset(options)
      automatically "mousedrag #{options[:to][:left]} #{options[:to][:top]}"
    end

    ##
    # Sends the characters into the active control in the active window.

    def type(str)
      execute_applescript(%Q'
    	  tell application "System Events"
          set frontApp to name of first item of (processes whose frontmost is true)
          tell application frontApp
    		    keystroke "#{str}"
  		    end
    	  end tell    
      ')
      pause 1
    end

    # Sends the keycode (a hex value) to the active control in the active 
    # window. For more about keycode values, see Mac Developer documentation.
    #
    def hit(key)
      automatically "hit #{key}"
    end

    # Don't do anything for the specified number of seconds (can be portions
    # of a second).
    #
    def pause(seconds)
      sleep seconds
    end

    # Use Leopard's native text-to-speech functionality to emulate a human
    # voice saying the narrative text.
    #
    def say(narrative)
      run(%Q`say "#{escape_dq(narrative)}"`)
    end
    
    ##
    # Click a menu item in any application.
    #
    # The name of the application should be the first argument.
    #
    # Three dots will be automatically replaced by the appropriate ellipsis.
    #
    #   click_menu_item("TextMate", "Navigation", "Go to Symbol...")
    
    def click_menu_item(*items)
      items_as_applescript_array = items.map {|i| i.gsub!('...', "…"); %("#{i}")}.join(", ")
      ascript = %Q(
      -- menu_click, by Jacob Rus, September 2006
      -- http://www.macosxhints.com/article.php?story=20060921045743404
      -- 
      -- Accepts a list of form: `{"Finder", "View", "Arrange By", "Date"}`
      -- Execute the specified menu item.  In this case, assuming the Finder 
      -- is the active application, arranging the frontmost folder by date.

      on menu_click(mList)
      	local appName, topMenu, r

      	-- Validate our input
      	if mList's length < 3 then error "Menu list is not long enough"

      	-- Set these variables for clarity and brevity later on
      	set {appName, topMenu} to (items 1 through 2 of mList)
      	set r to (items 3 through (mList's length) of mList)

      	-- This overly-long line calls the menu_recurse function with
      	-- two arguments: r, and a reference to the top-level menu
      	tell application "System Events" to my menu_click_recurse(r, ((process appName)'s ¬
      		(menu bar 1)'s (menu bar item topMenu)'s (menu topMenu)))
      end menu_click

      on menu_click_recurse(mList, parentObject)
      	local f, r

      	-- `f` = first item, `r` = rest of items
      	set f to item 1 of mList
      	if mList's length > 1 then set r to (items 2 through (mList's length) of mList)

      	-- either actually click the menu item, or recurse again
      	tell application "System Events"
      		if mList's length is 1 then
      			click parentObject's menu item f
      		else
      			my menu_click_recurse(r, (parentObject's (menu item f)'s (menu f)))
      		end if
      	end tell
      end menu_click_recurse


      menu_click({#{items_as_applescript_array}})
      )
      execute_applescript(ascript)
    end

    ##
    # Convenience method for grouping things into labeled blocks.
    #
    #   perform "Build CouchDB from source" do
    #     launch "Terminal"
    #     type "./configure"
    #     hit Enter
    #     ...
    #   end
    
    def perform(label)
      yield
    end

    ##
    # Hit a command key combo toward the currently active application.
    #
    # Use any combination of "command", "option", "control", "shift".
    # ("command" is the default).
    #
    # Case matters! It's easiest to use lowercase, then "shift" if needed.
    #
    #   keystroke "t"                     # COMMAND-t
    #   keystroke "k", "control", "shift" # A combo
    
    def keystroke(character, *special_keys)
      special_keys = ["command"] if special_keys.length == 0
      special_keys_as_applescript_array = special_keys.map {|k| "#{k} down"}.join(", ")
      execute_applescript(%Q'
    	  tell application "System Events"
          set frontApp to name of first item of (processes whose frontmost is true)
          tell application frontApp
    		    keystroke "#{character}" using {#{special_keys_as_applescript_array}}
  		    end
    	  end tell    
      ')
    end
    
    # Starts saying the narrative text, and simultaneously begins executing
    # the given block. Waits until both are finished.
    #
    def while_saying(narrative)
      if block_given?
        fork { say(narrative) }
        yield
        Process.wait
      else
        say(narrative)
      end
    end

    # Get a hash representing specific screen co-ordinates. Use in combination
    # with cursor, drag, launch, and similar methods.
    #
    def to(l, t, w = nil, h = nil)
      result = {
        :to => {
          :left => l,
          :top => t
        }
      }
      result[:to][:width] = w if w
      result[:to][:height] = h if h
      result
    end

    alias :at :to

    # Get a hash representing specific screen co-ordinates *relative to the
    # current mouse location.
    #
    def by(x, y)
      unless @cursor_loc
        @cursor_loc = automatically("mouselocation").strip.split(' ')
        @cursor_loc = {:x => @cursor_loc[0].to_i, :y => @cursor_loc[1].to_i}
      end
      to(@cursor_loc[:x] + x, @cursor_loc[:y] + y)
    end

    # The result of this method can be added +to+ a co-ordinates hash, 
    # offsetting the top and left values by the given margins.
    #
    def offset(x, y)
      { :offset => { :x => x, :y => y } }
    end


    # Returns a region hash describing the entire screen area. (May be wonky
    # for multi-monitor set-ups.)
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

    # Runs a shell command, performing fairly naive (but effective!) exit 
    # status handling. Returns the stdout result of the command.
    #
    def run(cmd)
      #puts("Executing: #{cmd}")
      result = `#{cmd}`
      raise Castanaut::Exceptions::ExternalActionError if $?.exitstatus > 0
      result
    end
  
    # Adds custom methods to this movie instance, allowing you to perform
    # additional actions. See the README.txt for more information.
    #
    def plugin(str)
      str.downcase!
      begin
        require File.join(File.dirname(@screenplay_path),"plugins","#{str}.rb")
      rescue LoadError
        require File.join(LIBPATH, "plugins", "#{str}.rb")
      end
      extend eval("Castanaut::Plugin::#{str.capitalize}")
    end

    # Loads a script from a file into a string, looking first in the
    # scripts directory beneath the path where Castanaut was executed,
    # and falling back to Castanaut's gem path.
    #
    def script(filename)
      @cached_scripts ||= {}
      unless @cached_scripts[filename]
        fpath = File.join(File.dirname(@screenplay_path), "scripts", filename)
        scpt = nil
        if File.exists?(fpath)
          scpt = IO.read(fpath)
        else
          scpt = IO.read(File.join(PATH, "scripts", filename))
        end
        @cached_scripts[filename] = scpt
      end

      @cached_scripts[filename]
    end

    # This stage direction is slightly different to the other ones. It collects
    # a set of directions to be executed when the movie ends, or when it is
    # aborted by the user. Mostly, it's used for cleaning up stuff. Here's
    # an example:
    #
    #   ishowu_start_recording
    #   at_end_of_movie do
    #     ishowu_stop_recording
    #   end
    #   move to(100, 100) # ... et cetera
    #
    # You can use this multiple times in your screenplay -- remember that if
    # the movie is aborted by the user before this direction is used, its
    # contents won't be executed. So in general, create an at_end_of_movie
    # block after every action that you want to revert (like in the example
    # above).
    def at_end_of_movie(&blk)
      @end_credits ||= []
      @end_credits << blk
    end

    protected
      def execute_applescript(scpt)
        File.open(FILE_APPLESCRIPT, 'w') {|f| f.write(scpt)}
        result = run("osascript #{FILE_APPLESCRIPT}")
        File.unlink(FILE_APPLESCRIPT)
        result
      end

      def automatically(cmd)
        run("#{osxautomation_path} \"#{cmd}\"")
      end

      def escape_dq(str)
        str.gsub(/\\/,'\\\\\\').gsub(/"/, '\"')
      end

      def combine_options(*args)
        options = args.inject({}) { |result, option| result.update(option) }
      end

    private
      def osxautomation_path
        File.join(PATH, "cbin", "osxautomation")
      end

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

      def apply_offset(options)
        return unless options[:to] && options[:offset]
        options[:to][:left] += options[:offset][:x] || 0
        options[:to][:top] += options[:offset][:y] || 0
      end

      def mouse_button_translate(btn)
        return btn if btn.is_a?(Integer)
        {"left" => 1, "right" => 2, "middle" => 3}[btn]
      end

      def roll_credits
        return unless @end_credits && @end_credits.any?
        @end_credits.each {|credit| credit.call}
      end
      
  end
end
