module Castanaut; module Compatibility
  require "bigdecimal"
  require "bigdecimal/math"

  # The MacOsXTiger class is intended to work on machines running
  # Mac OS X 10.4.x  In order for this compatibility layer to work
  # correctly, the Extras Suites application must be installed.
  # Get it at <http://www.kanzu.com/main.html#extrasuites>
  #
  # == Known limitations
  # === Not supported
  # * Movie#mousedown
  # * Movie#mouseup
  # * Movie#drag
  # === Partially supported
  # * click - only work with left-clicks
  #
  class MacOsXTiger < MacOsX

    # Returns true if the computer should use this compatibility layer.
    #
    def self.version_check
      !!`/usr/bin/sw_vers -productVersion`.index(/10\.4\.\d+/)
    rescue
      false
    end

    # Identifies this compatibility version
    def to_s
      "Mac OS 10.4 (Tiger)"
    end

    # See Movie#cursor for documentation
    def cursor(dst_loc)
      start_arr ||= execute_applescript(%Q`
        tell application "Extra Suites"
          ES mouse location
        end tell
      `).to_s.split(',').collect{|p| p.to_s.to_i}
      start_loc = {:x=>start_arr[0], :y=>start_arr[1]}
      dist = {
        :x=>(start_loc[:x] - dst_loc[:x]),
        :y=>(start_loc[:y] - dst_loc[:y])
      }
      steps = dist.values.collect{|p| p.to_s.to_i.abs}.max / 10.0

      dist = {:x=>dist[:x] / BigDecimal.new(steps.to_s), :y=>dist[:y] / BigDecimal.new(steps.to_s)}

      execute_applescript(%Q`
        tell application "Extra Suites"
          set x to #{start_loc[:x]}
          set y to #{start_loc[:y]}
          repeat while x #{dist[:x] > 0 ? '>' : '<'} #{dst_loc[:x]} or y #{dist[:y] > 0 ? '>' : '<'}  #{dst_loc[:y]}
            ES move mouse {x, y}
            set x to x - #{dist[:x].round(2)}
            set y to y - #{dist[:y].round(2)}
            delay 1.0E-6
          end repeat
          ES move mouse {#{dst_loc[:x]}, #{dst_loc[:y]}}
        end tell
      `)
    end

    # See Movie#cursor_location for documentation
    def cursor_location
      loc = execute_applescript(%Q`
      tell application "Extra Suites"
        ES mouse location
      end tell
      `).split(/\D+/)
      {:x => loc[0].to_i, :y => loc[1].to_i}
    end

    # See Movie#click for documentation
    def click(btn)
      not_supported "anything other than left clicking" unless btn == 'left'
      execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse
        end tell
      `)
    end

    # See Movie#doubleclick for documentation
    def doubleclick(btn)
      not_supported "anything other than left clicking" unless btn == 'left'
      execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse with double click
        end tell
      `)
    end

    # See Movie#tripleclick for documentation
    def tripleclick(btn)
      not_supported "anything other than left clicking" unless btn == 'left'
      execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse
          ES click mouse
          ES click mouse
        end tell
      `)
    end

    # See Movie#type for documentation
    def type(str, opts = {})
      return super  if opts[:applescript]

      case opts[:speed]
      when 0
        str = %Q`ES type string "#{ movie.escape_dq(str) }" with use clipboard`
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
      execute_applescript(%Q`
      tell application "Extra Suites"
        #{ str }
      end tell
      `)
    end

    # See Movie#hit for documentation
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
      execute_applescript(script)
    end

    private
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
