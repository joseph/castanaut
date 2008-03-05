module Castanaut; module Compatibility
  
  class Leopard
    
    def initialize(movie)
      raise ArgumentError.new("First argument must be a Castanaut::Movie") unless movie.is_a?(Castanaut::Movie)
      @movie = movie
      
      perms_test
    end
    
    def to_s
      "Mac OS 10.5 (Leopard)"
    end
    
    def cursor(dst_loc)
      automatically "mousemove #{dst_loc[:x]} #{dst_loc[:y]}"
    end
    
    def click(btn)
      automatically "mouseclick #{mouse_button_translate(btn)}"
    end
    
    def doubleclick(btn = 'left')
      automatically "mousedoubleclick #{mouse_button_translate(btn)}"
    end
    
    def tripleclick(btn = 'left')
      automatically "mousetripleclick #{mouse_button_translate(btn)}"
    end
    
    def mousedown(btn = 'left')
      automatically "mousedown #{mouse_button_translate(btn)}"
    end
    
    def mouseup(btn = 'left')
      automatically "mouseup #{mouse_button_translate(btn)}"
    end
    
    def drag(*options)
      options = combine_options(*options)
      apply_offset(options)
      automatically "mousedrag #{options[:to][:left]} #{options[:to][:top]}"
    end
    
    def type(str)
      automatically "type #{str}"
    end
    
    def hit(key)
      automatically "hit #{key}"
    end
    
  protected
    def automatically(cmd)
      movie.run("#{osxautomation_path} \"#{cmd}\"")
    end
    
  private
    def movie
      
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
  
    def osxautomation_path
      File.join(PATH, "cbin", "osxautomation")
    end
    
    def mouse_button_translate(btn)
      return btn if btn.is_a?(Integer)
      {"left" => 1, "right" => 2, "middle" => 3}[btn]
    end
    
  end
end; end