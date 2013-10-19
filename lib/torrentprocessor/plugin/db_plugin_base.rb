##############################################################################
# File::    db_plugin_base.rb
# Purpose:: Plugin helper classes.
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
    # DBPluginBase class
    class DBPluginBase


      def DBPluginBase.register_cmds
        {".test" => Command.new(DBPluginBase, :test, "Test command"),
          ".test2" => Command.new(DBPluginBase, :test2, "Another command")}
      end


      def initialize()

      end


      def test(args)
        puts "Test fired with args: #{args.inspect}"
      end


      def test2(args)
        puts "Test2 fired with args: #{args.inspect}"
      end
    end # class DBPluginBase
  end # module Plugin
end # module TorrentProcessor
