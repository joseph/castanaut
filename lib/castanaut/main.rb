module Castanaut

  # When running the Castanaut library as an executable, this class manages
  # the invocation of the user-specified screenplay.
  class Main

    # If Castanaut is not running, this runs the movie specified as the first
    # argument. If it *is* already running, this nixes the flag file, which
    # should cause Castanaut to stop.
    def self.run(args)
      if File.exists?(Castanaut::FILE_RUNNING)
        File.unlink(Castanaut::FILE_RUNNING)
      else
        Castanaut::Movie.spawn(args.shift)
      end
    end

  end

end
