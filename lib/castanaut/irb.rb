module Castanaut
  # The Irb module lets you use all of the Castanaut commands interactively from
  # the console.
  #
  # To get started open irb & type the following
  #   require 'rubygems'
  #   require 'castanaut'
  #   include Castanaut::Irb
  #   prepare_movie
  #
  # If you want you can also define a default_application, which will be
  # launched before each command is executed.
  #   default_app 'Safari'
  #
  module Irb

    # Launches an interactive Castanaute movie
    def prepare_movie(app_name = nil)
      default_app(app_name)
      @_castanaut_movie = Movie.new
      
      @_castanaut_movie.public_methods(false).each do |meth|
        (class << self; self; end).class_eval do
          define_method meth do |*args|
            @_castanaut_movie.launch(@_default_app) if default_app_for? meth
            @_castanaut_movie.send(meth, *args)
          end
        end
      end
      true
    end

    # Set a default application that will be launched before executing each
    # command. Run default_app(nil) if you don't want a default application
    def default_app(app_name)
      @_default_app = app_name
    end

    private
    # You shouldn't launch the default_app in the following cases.
    def default_app_for?(meth)
      return false unless @_default_app
      @_no_default_app_for ||= [:launch, :plugin, :script]
      !@_no_default_app_for.include?(meth.to_s.intern)
    end

    # While prepare_movie makes all public methods of the movie class available
    # in the irb, overriding method_missing makes all OS-specific & plugin methods
    # available as well.
    def method_missing(*args, &block)
      begin
        @_castanaut_movie.launch(@_default_app) if default_app_for? args.first
        @_castanaut_movie.send(*args, &block)
      rescue
        case $!
        when SystemStackError
          puts "NameError: undefined local variable or method '#{ args[0] }'"
        else
          puts "#{ $!.class }: #{ $!.to_s }"
        end
      end
    end

  end
end