module Castanaut

  module Plugin
    # This module provides actions for controlling Safari. It's tested against
    # Safari 5.1.2 on Mac OS X 10.7.2.
    module Safari

      # An applescript fragment by the Movie launch method to determine
      # whether a Safari browser window is open or not.
      def ensure_window_for_safari
        "if (count(windows)) < 1 then make new document"
      end

      # An applescript fragment by the Movie launch method to position
      # the window.
      def positioning_for_safari
        nil
      end

      # Open a URL in the front Safari tab.
      def url(str)
        execute_javascript("location.href = '#{str}'");
      end
      
      # Create a new tab in the front Safari window.
      def new_tab(str = nil)
        if str.nil?
          execute_applescript %Q`
            tell front window of application "Safari"
                set the current tab to (make new tab)
            end tell
          `
        else
          execute_applescript %Q`
            tell front window of application "Safari"
                set newTab to make new tab
                set the URL of newTab to "#{str}"
                set the current tab to newTab
            end tell
          `
        end
      end

      # Sleep until the specified element appears on-screen. Use this if you
      # want to wait until the a page or AJAX request has finished loading
      # before proceding to the next command.
      #
      # Options include:
      # * :timeout - maximum number of seconds to wait for the element to
      #     appear. Defaults to 10.
      # * :index - an integer (*n*) that gets the *n*th element matching the
      #     selector. Defaults to the first element.
      #     appear. Defaults to 10.
      # * :index - an integer (*n*) that gets the *n*th element matching the
      #     selector. Defaults to the first element.
      #
      def wait_for_element(selector, options = {})
        timeout = Time.now.to_i + (options[:timeout] || 10).to_i
        while true
          begin
            coords = element_coordinates(selector, options)
            return coords unless coords.nil?
          rescue Castanaut::Exceptions::ElementNotFound > e
            raise e if Time.now.to_i > timeout
          end
          sleep 0.3
        end
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
      # * :timeout - maximum seconds to wait for the element to appear.
      #   Useful if you're waiting for a page load or AJAX call to complete
      #   Defaults to 0.
      #
      def to_element(selector, options = {})
        pos = options.delete(:area)
        if options[:timeout]
          wait_for_element(selector, options)
          options.delete(:timeout)
        end
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

        def execute_javascript(scpt)
          execute_applescript %Q`
            tell application "Safari"
              set the_result to (do JavaScript "
                (function() {
                  #{escape_dq(scpt)}
                })();
              " in front document)
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
            return Castanaut.Coords.forElement(
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
    # When getting an element's coordinates, this is raised if no element on
    # the page matches the selector given.
    class ElementNotFound < CastanautError
    end

    # When getting an element's coordinates, this is raised if the element
    # is found, but cannot be shown on the screen. Normally, we automatically
    # scroll to an element that is currently off-screen, but sometimes that
    # might not be possible (such as if the element is display: none).
    class ElementOffScreen < CastanautError
    end
  end

end