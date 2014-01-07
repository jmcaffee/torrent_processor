##############################################################################
# File::    processor_plugin_manager.rb
# Purpose:: Plugin Manager for processor plugins
# 
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::ProcessorPlugin

  class ProcessorPluginManager < TorrentProcessor::PluginManagerBase

    def ProcessorPluginManager.execute_each context, args
      self.registered_plugins.each do |klass|
        klass.new.execute context, args
      end
    end
  end
end # module
