##############################################################################
# File::    plugin.rb
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
    # Tester class
    class Tester

      def run_test
        PluginManager.register_plugin(:db, DBPluginBase)
        puts PluginManager.command_list(:db).inspect
        PluginManager.command(".test", self, ".test data")
        PluginManager.command(".test2", self, ".test2 data")
      end
    end # class Tester
  end # module Plugin
end # module TorrentProcessor

require_relative('plugin/plugin_manager')
require_relative('plugin/command')
require_relative('plugin/db_plugin_base')
