module Castanaut; module OS; module MacOSX

  # The TigerMovie class is intended to work on machines running
  # Mac OS X 10.4.x. In order for it to work correctly, the Extras Suites
  # application must be installed.
  #
  # Get it at <http://www.kanzu.com/main.html#extrasuites>
  #
  # KNOWN LIMITATIONS
  #
  #   Not supported:
  #   * Movie#mousedown
  #   * Movie#mouseup
  #   * Movie#drag
  #
  #   Partially supported:
  #   * click - only work with left-clicks
  #
  class TigerMovie < Castanaut::OS::MacOSX::Movie

    register("Mac OS X 10.4")


    # Returns true if the current platform is Mac OS X 10.4.
    #
    def self.platform_supported?
      vers = `/usr/bin/sw_vers -productVersion`.match(/10\.(\d)/)
      vers[1].to_i == 4
    rescue
      false
    end


    #--------------------------------------------------------------------------
    # KEYBOARD INPUT DIRECTIONS
    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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


    def keystroke(*args)
      not_supported("keystroke")
    end


    def type(str, opts = {})
      type_via_applescript(str, opts)
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


      start_arr ||= execute_applescript(%Q`
        tell application "Extra Suites"
          ES mouse location
        end tell
      `).to_s.split(',').collect{|p| p.to_s.to_i}
      start_loc = {:x=>start_arr[0], :y=>start_arr[1]}
      dist = {
        :x=>(start_loc[:x] - @cursor_loc[:x]),
        :y=>(start_loc[:y] - @cursor_loc[:y])
      }
      steps = dist.values.collect{|p| p.to_s.to_i.abs}.max / 10.0

      dist = {:x=>dist[:x] / BigDecimal.new(steps.to_s), :y=>dist[:y] / BigDecimal.new(steps.to_s)}

      execute_applescript(%Q`
        tell application "Extra Suites"
          set x to #{start_loc[:x]}
          set y to #{start_loc[:y]}
          repeat while x #{dist[:x] > 0 ? '>' : '<'} #{@cursor_loc[:x]} or y #{dist[:y] > 0 ? '>' : '<'}  #{@cursor_loc[:y]}
            ES move mouse {x, y}
            set x to x - #{dist[:x].round(2)}
            set y to y - #{dist[:y].round(2)}
            delay 1.0E-6
          end repeat
          ES move mouse {#{@cursor_loc[:x]}, #{@cursor_loc[:y]}}
        end tell
      `)
    end


    def cursor_location
      loc = execute_applescript(%Q`
      tell application "Extra Suites"
        ES mouse location
      end tell
      `).split(/\D+/)
      {:x => loc[0].to_i, :y => loc[1].to_i}
    end


    def click(btn = "left")
      not_supported "anything other than left clicking"  unless btn == 'left'
      execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse
        end tell
      `)
    end


    def doubleclick(btn = "left")
      not_supported "anything other than left clicking"  unless btn == 'left'
      execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse with double click
        end tell
      `)
    end


    def tripleclick(btn = "left")
      not_supported "anything other than left clicking"  unless btn == 'left'
      execute_applescript(%Q`
        tell application "Extra Suites"
          ES click mouse
          ES click mouse
          ES click mouse
        end tell
      `)
    end


    def mousedown(*args)
      not_supported("mousedown")
    end


    def mouseup(*args)
      not_supported("mouseup")
    end


    def drag(*options)
      not_supported("drag")
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

end; end; end
