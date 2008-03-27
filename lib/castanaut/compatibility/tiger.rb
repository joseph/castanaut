module Castanaut; module Compatibility
  require "bigdecimal"
  require "bigdecimal/math"
  
  class Tiger < MacOSX
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
        tell application "Extra Suites"
          set x to #{start_loc[:x]}
          set y to #{start_loc[:y]}
          repeat while x #{dist[:x] > 0 ? '>' : '<'} #{dst_loc[:x]} or y #{dist[:y] > 0 ? '>' : '<'}  #{dst_loc[:y]}
            ES move mouse {x, y}
            set x to x - #{dist[:x].round(2)}
            set y to y - #{dist[:y].round(2)}
            delay 1.0E-6
          end repeat
          move mouse {#{dst_loc[:x]}, #{dst_loc[:y]}}
        end tell
      `)
    end
    
    def click(btn)
      raise ArgumentError.new("Only left clicking is supported") unless btn == 'left'
      movie.execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse
        end tell
      `)
    end
    
    def doubleclick(btn)
      raise ArgumentError.new("Only left clicking is supported") unless btn == 'left'
      movie.execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse with double click
        end tell
      `)
    end
    
    def tripleclick(btn)
      raise ArgumentError.new("Only left clicking is supported") unless btn == 'left'
      movie.execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse
          ES click mouse
          ES click mouse
        end tell
      `)
    end
    
    def type(str, opts)
      case opts[:speed]
      when nil, 0
        str.gsub!('"', '"& quote &"')
        str = %Q`ES type string "#{ str }" with use clipboard`
      else
        opts[:speed] = BigDecimal.new(opts[:speed].to_s)
        opts[:speed] = BigDecimal.new('50') unless opts[:speed] > 0
        str = str.split(//u).collect do |s|
          case s
          when '"'
            s = %Q`
               ES type string quote with use clipboard
               `
          else
            s = %Q`
               ES type string "#{s}"
               `
          end
          s += "delay #{ (1 / opts[:speed]).round(2) }"
        end
      end
      movie.execute_applescript(%Q`
      tell application "Extra Suites"
        #{ str }
      end tell
      `)
    end
    
    def hit(key, *modifiers)
      script = ''
      if key == '"'
        type(key)
        return
      elsif key.index('0x') == 0
        script = hit_with_system_events(key, *modifiers)
      else
        script = hit_with_extra_suites(key, *modifiers)
      end
      puts script
      movie.execute_applescript(script)
    end
    
    private
    def movie
      @movie
    end
    
    def hit_with_extra_suites(key, *modifiers)
      str = %Q{"#{ key }"}
      if !modifiers.empty?
        modifiers = modifiers.collect do |mod|
          case mod
          when Castanaut::Command
            "command"
          when Castanaut::Ctrl
            "control"
          when Castanaut::Alt
            "option"
          when Castanaut::Shift
            "shift"
          else
            nil
          end
        end.select{ |mod| !mod.nil? }

        str += modifiers.empty? ? "" : " with #{ modifiers.join(' and ') }"
      end
      
      %Q`
      tell application "Extra Suites"
        ES type key #{ str }
      end tell
      `
    end
    
    def hit_with_system_events(key, *modifiers)
      str = key.hex.to_s
      if !modifiers.empty?
        modifiers = modifiers.collect do |mod|
          case mod
          when Castanaut::Command
            "command down"
          when Castanaut::Ctrl
            "control down"
          when Castanaut::Alt
            "option down"
          when Castanaut::Shift
            "shift down"
          else
            nil
          end
        end.select{ |mod| !mod.nil? }
        str += modifiers.empty? ? "" : " using {#{ modifiers.join(', ') }}"
      end
        
      %Q`
      tell application "System Events"
        key code #{ str }
      end tell
      `
    end
    
  end
end; end