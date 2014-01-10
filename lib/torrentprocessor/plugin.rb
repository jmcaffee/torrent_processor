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
module TorrentProcessor::Plugin

  class PluginError < StandardError; end

end # module TorrentProcessor::Plugin

require_relative('plugin/cmd_plugin_manager')
require_relative('plugin/command')
require_relative('plugin/rss_plugin')
require_relative('plugin/movie_mover')
require_relative('plugin/movie_db')
require_relative('plugin/unrar')
require_relative('plugin/torrent_copier')
require_relative('plugin/plugin_manager_base')
require_relative('plugin/processor_plugin_manager')

