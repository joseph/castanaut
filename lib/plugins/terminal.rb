module Castanaut

  module Plugin
    # This module provides actions for controlling Terminal.app
    # Terminal 2.0.1 on Mac OS X 10.5.6
    module Terminal

      # Open a URL in the front Safari tab.
      def url(str)
        execute_applescript(%Q`
          tell application "safari" 
            do JavaScript "location.href = '#{str}'" in front document 
          end tell
        `)
      end

      # Get the co-ordinates of an element in the front Safari tab. Use this
      # with Castanaut::Movie#cursor to send the mouse cursor to the element.
      #
      # Options include:
      # * :index - an integer (*n*) that gets the *n*th element matching the 
      #   selector. Defaults to the first element.
      # * :area - whereabouts in the element do you want the coordinates. 
      #   Valid values are: left, center, right, and top, middle, bottom. 
      #   Defaults to ["center", "middle"].
      #   If single axis is given (eg "left"), the other axis uses its default.
      def to_element(selector, options = {})
        pos = options.delete(:area)
        coords = element_coordinates(selector, options)

        x_axis, y_axis = [:center, :middle]
        [pos].flatten.first(2).each do |p|
          p = p.to_s.downcase
          x_axis = p.to_sym if %w[left center right].include?(p)
          y_axis = p.to_sym if %w[top middle bottom].include?(p)
        end
        
        edge_offset = options[:edge_offset] || 3
        case x_axis
          when :left
            x = coords[0] + edge_offset
          when :center
            x = (coords[0] + coords[2] * 0.5).to_i 
          when :right
            x = (coords[0] + coords[2]) - edge_offset
        end

        case y_axis
          when :top
            y = coords[1] + edge_offset
          when :middle
            y = (coords[1] + coords[3] * 0.5).to_i
          when :bottom
            y = (coords[1] + coords[3]) - edge_offset
        end

        result = { :to => { :left => x, :top => y } }
      end

      private
        # Note: the script should set the Castanaut.result variable.
        def execute_javascript(scpt)
          execute_applescript %Q`
            tell application "Safari"
              do JavaScript "
                document.oldTitle = document.title;
                #{escape_dq(scpt)}
                if (typeof Castanaut.result != 'undefined') {
                  document.title = Castanaut.result;
                }
              " in front document
              set the_result to ((name of window 1) as string)
              do JavaScript "
                document.title = document.oldTitle;
              " in front document
              return the_result
            end tell
          `
        end

        def element_coordinates(selector, options = {})
          index = options[:index] || 0
          gebys = script('gebys.js')
          cjs = script('coords.js')
          coords = execute_javascript(%Q`
            #{gebys}
            #{cjs}
            Castanaut.result = Castanaut.Coords.forElement(
              '#{selector}',
              #{index}
            );
          `)

          unless coords.match(/\d+ \d+ \d+ \d+/)
            raise Castanaut::Exceptions::ElementNotFound
          end

          coords = coords.split(' ').collect {|c| c.to_i}

          if coords.any? {|c| c < 0 }
            raise Castanaut::Exceptions::ElementOffScreen
          end

          coords
        end

    end
  end 

  module Exceptions
  end

end
