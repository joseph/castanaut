module Castanaut; module Compatibility
  require "bigdecimal"
  require "bigdecimal/math"
  
  class Tiger
    
    def initialize(movie)
      raise ArgumentError.new("First argument must be a Castanaut::Movie") unless movie.is_a?(Castanaut::Movie)
      @movie = movie
    end
    
    def to_s
      "Mac OS 10.4 (Tiger)"
    end
    
    def cursor(dst_loc)
      start_arr ||= movie.execute_applescript("mouse location").to_s.split(',').collect{|p| p.to_s.to_i}
      start_loc = {:x=>start_arr[0], :y=>start_arr[1]}
      dist = {
        :x=>(start_loc[:x] - dst_loc[:x]),
        :y=>(start_loc[:y] - dst_loc[:y])
      }
      steps = dist.values.collect{|p| p.to_s.to_i.abs}.max / 10.0
      
      dist = {:x=>dist[:x] / BigDecimal.new(steps.to_s), :y=>dist[:y] / BigDecimal.new(steps.to_s)}
      
      movie.execute_applescript(%Q`
        set x to #{start_loc[:x]}
        set y to #{start_loc[:y]}
        repeat while x #{dist[:x] > 0 ? '>' : '<'} #{dst_loc[:x]} or y #{dist[:y] > 0 ? '>' : '<'}  #{dst_loc[:y]}
        	move mouse {x, y}
        	set x to x - #{dist[:x].round(2)}
        	set y to y - #{dist[:y].round(2)}
        	delay 1.0E-6
        end repeat
        move mouse {#{dst_loc[:x]}, #{dst_loc[:y]}}
      `)
    end
    
    def click(btn = 'left')
      raise ArgumentError.new("Only left clicking is supported") unless btn == 'left'
      movie.execute_applescript("mouse clisk")
    end
    
    def doubleclick(btn = 'left')
      raise ArgumentError.new("Only left clicking is supported") unless btn == 'left'
      movie.execute_applescript("double mouse clisk")
    end
    
    def tripleclick(btn = 'left')
      raise ArgumentError.new("Only left clicking is supported") unless btn == 'left'
      movie.execute_applescript(movie.execute_applescript(Array.new(3,"mouse clisk").join("\n")))
    end
    
    def type(str, opts = {})
      opts[:speed] = BigDecimal.new(opts[:speed].to_s)
      opts[:speed] = BigDecimal.new('50') unless opts[:speed] > 0
      str = str.split(//u).collect do |s|
        %Q`
           keystroke "#{s}"
           delay #{ (1 / opts[:speed]).round(2) }`
      end
      movie.execute_applescript(%Q`
      tell application "System Events"
      	#{ str }
      end tell
      `)
    end
    
    # I'll implement hit soon. It should be supported by the XTool additions as well.
    #def hit(key)
    #  
    #end
    
    private
    def movie
      @movie
    end
    
  end
end; end