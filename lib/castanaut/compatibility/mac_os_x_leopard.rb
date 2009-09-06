module Castanaut; module Compatibility
  
  # The MacOsXLeopard class is intended to work on machines running 
  # Mac OS X 10.5.x
  #
  # == Known limitations
  # === Partially working
  # * type - does not support the :speed option
  # * hit - only works with special keys (those in keys.rb) not
  #   other characters (like 'a')
  # * hit - does not support modifier keys
  #
  class MacOsXLeopard < MacOsX
    
    # Returns true if the computer should use this compatibility layer.
    #
    def self.version_check
      !!`/usr/bin/sw_vers -productVersion`.index(/10\.5\.\d+/)
    rescue
      false
    end
    
    def initialize(movie)
      super(movie)
      perms_test
    end
    
    # Identifies this compatibility version
    def to_s
      "Mac OS 10.5 (Leopard)"
    end
    
    # See Movie#cursor for documentation
    def cursor(dst_loc)
      automatically "mousemove #{dst_loc[:x]} #{dst_loc[:y]}"
    end
    
    # See Movie#cursor_location for documentation
    def cursor_location
      loc = automatically("mouselocation").strip.split(' ')
      {:x => loc[0].to_i, :y => loc[1].to_i}
    end
    
    # See Movie#click for documentation
    def click(btn)
      automatically "mouseclick #{mouse_button_translate(btn)}"
    end
    
    # See Movie#doubleclick for documentation
    def doubleclick(btn)
      automatically "mousedoubleclick #{mouse_button_translate(btn)}"
    end
    
    # See Movie#tripleclick for documentation
    def tripleclick(btn)
      automatically "mousetripleclick #{mouse_button_translate(btn)}"
    end
    
    # See Movie#mousedown for documentation
    def mousedown(btn)
      automatically "mousedown #{mouse_button_translate(btn)}"
    end
    
    # See Movie#mouseup for documentation
    def mouseup(btn)
      automatically "mouseup #{mouse_button_translate(btn)}"
    end
    
    # See Movie#drag for documentation
    def drag(*options)
      options = combine_options(*options)
      apply_offset(options)
      automatically "mousedrag #{options[:to][:left]} #{options[:to][:top]}"
    end

    # See Movie#type for documentation
    def type(str, opts = {})
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
    end

    # See Movie#hit for documentation
    def hit(key, *modifiers)
      not_supported "modifier keys for the 'hit' method" unless modifiers.empty?
      automatically "hit #{key}"
    end
    
  protected
    def automatically(cmd)
      movie.run("#{osxautomation_path} \"#{cmd}\"")
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
end; end
