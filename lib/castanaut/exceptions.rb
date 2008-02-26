module Castanaut
  # All Castanaut errors are defined within this module. If you are creating
  # a plugin, you should re-open this module in your plugin script file to 
  # add any plugin-specific exceptions (it's also a good idea to have them 
  # descend from CastanautError).
  module Exceptions
    # The abstract parent class of all Castanaut errors.
    class CastanautError < RuntimeError
    end

    # Raised if Castanaut was invoked with no screenplay argument, or one
    # pointing to a non-existent file.
    class ScreenplayNotFound < CastanautError
    end

    # If Castanaut::Movie#run sees a non-zero exit status from the shell 
    # process, this error will be raised.
    class ExternalActionError < CastanautError
    end

    # If the FILE_RUNNING flag file is deleted or moved during the execution
    # of a movie, it will terminate and raise this exception.
    class AbortedByUser < CastanautError
    end

    # Despite asking for permission, the osxautomation utility in cbin cannot
    # be executed. This is pretty fatal to our intentions, so we abort with
    # this exception.
    class OSXAutomationPermissionError < CastanautError
    end
  end
end
