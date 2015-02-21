##############################################################################
# File::    q_bit_torrent.rb
# Purpose:: qBittorrent Service module
# 
# Author::    Jeff McAffee 2015-02-07
# Copyright:: Copyright (c) 2015, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor
  module Service
    module Qbittorrent
    end
  end
end

require_relative 'q_bit_torrent/torrent_data'
#require_relative 'qbittorrent/rss_torrent_data'
require_relative 'q_bit_torrent/client'
