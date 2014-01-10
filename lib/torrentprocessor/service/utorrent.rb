##############################################################################
# File::    utorrent.rb
# Purpose:: UTorrent Service files
# 
# Author::    Jeff McAffee 01/09/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor
  module Service
    module UTorrent
    end
  end
end

require_relative 'utorrent/torrent_data'
require_relative 'utorrent/rss_torrent_data'
require_relative 'utorrent/utorrentwebui'
