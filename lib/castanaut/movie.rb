require 'find'

module Castanaut

  # The movie class is the containing context within which screenplays are
  # invoked. It provides a number of basic stage directions for your
  # screenplays, and can be extended with plugins.
  #
  # If you're working to make Castanaut compatible with your operating system,
  # you must make sure that *all* methods in this class work correctly.
  class Movie

    #  Creates the movie. If a screenplay is provided here, it will be run.
    #  If monitor is true, we'll monitor the kill file (FILE_RUNNING) -
    #  if it is deleted, we abort.
    #
    def initialize(screenplay = nil, monitor = true)
      if screenplay
        monitor ? _play_and_monitor(screenplay) : _play(screenplay)
      end
    end


    # Simply plays the screenplay in the current thread.
    def _play(screenplay)
      unless File.exists?(@screenplay_path = screenplay)
        raise Castanaut::Exceptions::ScreenplayNotFound
      end
      eval(IO.read(@screenplay_path), binding)
      roll_credits
    end


    # Plays the screenplay in a separate thread, and monitors the killfile
    # (which is at FILE_RUNNING) - if it is deleted, the screenplay will
    # abort.
    def _play_and_monitor(screenplay)
      unless File.exists?(@screenplay_path = screenplay)
        raise Castanaut::Exceptions::ScreenplayNotFound
      end

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
    # If the options hash is given, it should contain the co-ordinates for
    # the window.
    #
    # Examle:
    #
    #   launch "Firefox", at(10, 10, 800, 600)
    #
    def launch(app_name, *options)
      options = combine_options(*options)

      compatible_call :launch, app_name, options
    end


    # Returns a region hash describing the entire screen area.
    #
    # Expects compatible_call to return a hash with :width & :heigt keys.
    #
    def screen_size
      compatible_call :screen_size
    end


    # Get a hash representing the current mouse cursor co-ordinates.
    #
    # Expects compatible_call to return a hash with :x & :y keys.
    #
    def cursor_location
      compatible_call :cursor_location
    end


    # Move the mouse cursor to the specified co-ordinates.
    # Example:
    #
    #   cursor to(20, 20)
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


    # Hit a single key on the keyboard (with optional modifiers).
    # Valid keys include any single character or any of the constants in keys.rb
    # Valid modifiers include one or more of the following: Command, Ctrl, Alt, Shift
    # Examples:
    #   hit Castanaut::Tab
    #   hit 'a', Castanaut::Command
    def hit(key, *modifiers)
      compatible_call :hit, key, *modifiers
    end


    # Don't do anything for the specified number of seconds (can be portions
    # of a second).
    #
    def pause(seconds)
      sleep seconds
    end


    # Use text-to-speech functionality to emulate a human
    # voice saying the narrative text.
    #
    def say(narrative)
      compatible_call :say, narrative
    end


    # Groups directions into labelled blocks. This lets you skip (see below)
    # to the end of the block if you need to.
    #
    #   perform "Build CouchDB from source" do
    #     launch "Terminal"
    #     type "./configure"
    #     hit Enter
    #     ...
    #   end
    #
    def perform(label)
      yield
    rescue Castanaut::Exceptions::SkipError => e
      puts "Skipping remaining directions in '#{label}'"
    end


    # Lets you skip out of a perform block if you need to. Usually raised
    # when some condition fails. For example:
    #
    # perform "Point to heading" do
    #
    #   move to_element('h2') rescue skip
    #   say "This is the heading."
    #
    # end
    #
    def skip
      raise Castanaut::Exceptions::SkipError
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
      @cursor_loc ||= cursor_location
      to(@cursor_loc[:x] + x, @cursor_loc[:y] + y)
    end


    # The result of this method can be added +to+ a co-ordinates hash,
    # offsetting the top and left values by the given margins.
    #
    def offset(x, y)
      { :offset => { :x => x, :y => y } }
    end


    # Runs a shell command, performing fairly naive (but effective!) exit
    # status handling. Returns the stdout result of the command.
    #
    def run(cmd)
      result = `#{cmd}`
      raise Castanaut::Exceptions::ExternalActionError if $?.exitstatus > 0
      result
    end


    # Loads a script from a file into a string, looking first in the
    # scripts directory beneath the path where Castanaut was executed,
    # and falling back to Castanaut's gem path.
    #
    def script(filename)
      @cached_scripts ||= {}
      unless @cached_scripts[filename]
        fpath = contextual_path("scripts", filename)
        if File.exists?(fpath)
          scpt = IO.read(fpath)
        else
          scpt = IO.read(File.join(PATH, "scripts", filename))
        end
        @cached_scripts[filename] = scpt
      end

      @cached_scripts[filename]
    end


    # Adds custom methods to this movie instance, allowing you to perform
    # additional actions. The str can be either the file name
    # (e.g. 'snapz_pro') or the class name (e.g. 'SnapzPro').
    # See the README.txt for more information.
    #
    def plugin(str)
      # copied stright from the Rails underscore helper
      str = str.to_s
      str.gsub!(/::/, '/')
      str.gsub!(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
      str.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      str.tr!("-", "_")
      str.downcase!
      fpath =
      begin
        require contextual_path("plugins", "#{str}.rb")
      rescue LoadError
        require File.join(LIBPATH, "plugins", "#{str}.rb")
      end
      # copied stright from the Rails camelize helper
      str = str.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
      extend eval("Castanaut::Plugin::#{str}")
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

      # Returns an instance of the compatibility layer for the current
      # operating system.
      #
      # Checks each class defined in the <gem_dir>/lib/castanaut/compatibility
      # directory by running the version_check method.
      #
      # If you're working to make Castanaut compatible with your operating system,
      # make sure YouCompatibilityLayer.version_check returns true on computers
      # running the appropraite OS.
      #
      def compatibility_version
        return @compatibility_version if @compatibility_version

        Find.find(File.join(LIBPATH, "castanaut", "compatibility")) do |path|
          path = path.match(/([^\/]*).rb$/)
          next unless path
          path = path[1]

          # copied stright from the Rails camelize helper
          path = path.to_s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }

          begin
            @compatibility_version = Object.module_eval("Castanaut::Compatibility::#{ path }")
            raise 'wrong version' unless @compatibility_version.version_check
            @compatibility_version = @compatibility_version.new(self)
          rescue
            @compatibility_version = nil
          end

          break if @compatibility_version
        end
        @compatibility_version
      end


      # The bread & butter of Castanaut's cross-OS compatibility.
      #
      def compatible_call(method, *options)
        compatibility_version.send(method, *options)
      rescue NameError
        not_supported "the \"#{method}\" action"
      end


      # Find a file relative to the movie execution context -- that is,
      # either the location of the screenplay file, or the present working
      # directory if there is no screenplay file.
      #
      def contextual_path(*args)
        if @screenplay_path
          File.join(*([File.dirname(@screenplay_path)] + args))
        else
          File.join(*args)
        end
      end


      # A method used by the compatibility layer to raise a NotSupportedError
      # explaining which requested options are not supported by the current
      # operating system.
      #
      # Example:
      #   # On a Mac OS 10.5 (Leopard) machine
      #   hit 'a', Castanaut::Command
      #   # => "Warning: Mac OS 10.5 (Leopard) doesn't support modifier keys for the 'hit' method."
      #
      def not_supported(message)
        raise Castanaut::Exceptions::NotSupportedError.new("Warning: #{ compatibility_version.to_s } doesn't support #{ message.gsub(/\.$/, '') }.")
      end


      # Escapes double quotes.
      #
      def escape_dq(str)
        str.gsub(/\\/,'\\\\\\').gsub(/"/, '\"')
      end


      # Combines a list of hashes into one hash.
      # Example:
      #
      #   combine_options({:x=>10}, {:y=>20})
      #   # => {:y=>20, :x=>10}
      #
      def combine_options(*args)
        args.inject({}) { |result, option| result.update(option) }
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


      # If a method isn't defined in the movie class, try doing a compatible_call.
      # This is the magic that allows methods like the execute_applescript to work
      # on Mac OS systems.
      #
      def method_missing(*args)
        compatible_call(*args)
      end

  end

end
