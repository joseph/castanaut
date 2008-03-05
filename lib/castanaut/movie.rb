module Castanaut
  # The movie class is the containing context within which screenplays are 
  # invoked. It provides a number of basic stage directions for your 
  # screenplays, and can be extended with plugins.
  class Movie

    # Runs the "screenplay", which is a file containing Castanaut instructions.
    #
    def initialize(screenplay)
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
      
      compatible_call :cursor, @cursor_loc
    end

    alias :move :cursor

    # Send a mouse-click at the current mouse location.
    #
    def click(btn = 'left')
      compatible_call :click, btn
    end

    # Send a double-click at the current mouse location.
    #
    def doubleclick(btn = 'left')
      compatible_call :doubleclick, btn
    end
    
    # Send a triple-click at the current mouse location.
    # 
    def tripleclick(btn = 'left')
      compatible_call :doubleclick, btn
    end

    # Press the button down at the current mouse location. Does not 
    # release the button until the mouseup method is invoked.
    #
    def mousedown(btn = 'left')
      compatible_call :mousedown, btn
    end

    # Releases the mouse button pressed by a previous mousedown.
    #
    def mouseup(btn = 'left')
      compatible_call :mouseup, btn
    end

    # "Drags" the mouse by (effectively) issuing a mousedown at the current 
    # mouse location, then moving the mouse to the specified coordinates, then
    # issuing a mouseup.
    #
    def drag(*options)
      compatible_call :drag, *options
    end

    # Sends the characters into the active control in the active window.
    #
    def type(str, opts = {})
      compatible_call :type, str, opts
    end

    # Sends the keycode (a hex value) to the active control in the active 
    # window. For more about keycode values, see Mac Developer documentation.
    #
    def hit(key)
      compatible_call :hit, key
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
    
    # Runs a script from a string.
    # Returns the result.
    #
    def execute_applescript(scpt)
      File.open(FILE_APPLESCRIPT, 'w') {|f| f.write(scpt)}
      result = run("osascript #{FILE_APPLESCRIPT}")
      File.unlink(FILE_APPLESCRIPT)
      result
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
      def compatible_call(method, *options)
        compatibility_version.send(method, *options)
      rescue NameError
        raise "Sorry, #{compatibility_version.to_s} doesn't support the \"#{method}\" action"
      end
      
      def compatibility_version
        @compatibility_version ||= case run("/usr/bin/sw_vers -productVersion")
        when /10\.4\.\d+/
          Castanaut::Compatibility::Tiger.new(self)
        else
          Castanaut::Compatibility::Leopard.new(self)
        end
        @compatibility_version
      end

      def escape_dq(str)
        str.gsub(/\\/,'\\\\\\').gsub(/"/, '\"')
      end

      def combine_options(*args)
        options = args.inject({}) { |result, option| result.update(option) }
      end

    private
      def apply_offset(options)
        return unless options[:to] && options[:offset]
        options[:to][:left] += options[:offset][:x] || 0
        options[:to][:top] += options[:offset][:y] || 0
      end

      def roll_credits
        return unless @end_credits && @end_credits.any?
        @end_credits.each {|credit| credit.call}
      end
      
  end
end
