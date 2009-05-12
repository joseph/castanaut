module Castanaut; module Plugin

# keystack castanaut plugin
# by trevor wennblom <trevor@corevx.com>
# 2009-04-23
#
# used in gnu screen demo
#   http://ninecoldwinters.com/ferro/gnuscreenscreencast
#
# castanaut can be found here:
# http://gadgets.inventivelabs.com.au/castanaut
#
# support multiple modifier keys to achieve the likes of Command-Tab
#
# modifiers allowed are :control, :command, :option, and :shift
# these can be passed as an array
#
# this does not account for input customization, so if you use dvorak your
# results will be interesting.
#
# license compatible with castanaut
# released under the terms of the WTFPL
# http://sam.zoy.org/wtfpl
#
  module Keystack

  # keycode press
  # keycode is a number mapped to a specific key on your keyboard, '0' and greater
    def keycode(k)
      k = k.to_i # if a number as type String was passed
      ascript = %Q`tell application "System Events" to key code #{k}`
      execute_applescript(ascript)
    end
  
  # keystroke such as 'a' or 'my sentence'
    def keystroke(k)
      ascript = %Q`tell application "System Events" to keystroke "#{k}"`
      execute_applescript(ascript)
    end

  # keystroke literal such as 'return' or 'tab'
  # example
  #   keystroke_literal('tab')
    def keystroke_literal(k, *modifiers)
      ascript = %Q`tell application "System Events" to keystroke #{k}`
      execute_applescript(ascript)
    end
    
  # keycode press with one or more modifier keys
  # keycode is a number mapped to a specific key on your keyboard, '0' and greater
    def keycode_using(k, *modifiers)
      k = k.to_i # if a number as type String was passed
      m = modifiers_to_array(modifiers)
      ascript = %Q`tell application "System Events" to key code #{k} using #{m}`
      execute_applescript(ascript)
    end
          
  # keystroke with one or more modifier keys
  # example
  #   keystroke('z', :command)
  #   keystroke('z', :command, :shift)
  #   keystroke('z', [:command, :shift])
    def keystroke_using(k, *modifiers)
      m = modifiers_to_array(modifiers)
      ascript = %Q`tell application "System Events" to keystroke "#{k}" using #{m}`
      execute_applescript(ascript)
    end
    
  # keystroke literal such as 'return' or 'tab' with one or more modifier keys
  # example
  #   keystroke_literal_using('tab', :command) # Command-Tab switch windows
    def keystroke_literal_using(k, *modifiers)
      m = modifiers_to_array(modifiers)
      ascript = %Q`tell application "System Events" to keystroke #{k} using #{m}`
      execute_applescript(ascript)
    end

  protected

    def modifiers_to_array(modifiers)
      ary = []
      raise "must be passed Array - received #{modifiers.inspect}'" unless modifiers.kind_of? Array
      modifiers.flatten! # accept keystroke('z', [:command, :shift])
      raise "must be passed Array with at least one element - received #{modifiers.inspect}'" if modifiers.empty?
      modifiers.map! do |m|
      # these are listed in the System Events dictionary
      # Applications/AppleScript/Script Editor -> File -> Open Dictionary -> System Events
        case m
        when :control
          'control down'
        when :command
          'command down'
        when :option
          'option down'
        when :shift
          'shift down'
        else
          raise "unrecognized '#{m.inspect}'"
        end
      end

      if modifiers.size > 1
        '{' + modifiers.join(', ') + '}'
      else
        modifiers.to_s
      end
    end

  end # module Keystack
  
end; end
