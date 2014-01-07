##############################################################################
# File::    processor_plugin.rb
# Purpose:: Processor plugin classes.
#
# Author::    Jeff McAffee 2013-10-20
# Copyright:: Copyright (c) 2013, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

##########################################################################
# TorrentProcessor module
module TorrentProcessor::ProcessorPlugin
end # module TorrentProcessor

require_relative('processor_plugin/movie_db')
require_relative('processor_plugin/movie_mover')
require_relative('processor_plugin/robocopy')
require_relative('processor_plugin/seven_zip')
require_relative('processor_plugin/torrent_copier_plugin')
require_relative('processor_plugin/processor_plugin_manager')

