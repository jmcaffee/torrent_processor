##############################################################################
# File::    plugin_manager_base.rb
# Purpose:: Base class for Plugin Manager classes
# 
# Author::    Jeff McAffee 01/06/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor

  class PluginManagerBase

    def self.register klass
      if klass.class == Array
        self.registered_plugins.concat klass
      else
        self.registered_plugins << klass
      end
    end

    def self.registered_plugins
      @registered_plugins ||= []
      @registered_plugins
    end

    def self.remove_all
      @registered_plugins = []
    end
  end # class
end # module
