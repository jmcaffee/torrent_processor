##############################################################################
# File::    command.rb
# Purpose:: Encapsulate a command
#
# Author::    Jeff McAffee 02/21/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

##########################################################################
# TorrentProcessor module
module TorrentProcessor



  ##########################################################################
  # Plugin module
  module Plugin


    ##########################################################################
    # Command class
    #
    # Object used to encapsulate a command, the method that should be called
    # when the command is activated, and a description of the command.
    class Command

      ###
      # *Args*
      #
      # +klass+ -- class constant (ie. Test) used to instanciate the object
      #
      # +mthd+ -- method symbol to call (ie. :some_method_name)
      #
      # +desc+ -- description of the command
      #
      def initialize(klass, mthd, desc)
        @klass = klass
        @mthd = mthd
        @desc = desc
      end


      ###
      # Return the command's description
      #
      def desc
        @desc
      end


      ###
      # Execute the command passing it any args provided.
      #
      # *Args*
      #
      # +args+ -- argument list to be passed to the command
      #
      def execute(*args)
        @klass.new.send( @mthd, args )
      end


    end # class Command
  end # module Plugin

end # module TorrentProcessor
