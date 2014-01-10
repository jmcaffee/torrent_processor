##############################################################################
# File::    torrent_data.rb
# Purpose:: Torrent Data object encapsulates data for one torrent.
#
# Author::    Jeff McAffee 08/07/2011
# Copyright:: Copyright (c) 2011, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

require 'ktcommon/ktpath'
require 'ktcommon/ktcmdline'


module TorrentProcessor::Service::UTorrent

  class TorrentData

    attr_accessor :hash
    attr_accessor :status
    attr_accessor :name
    attr_accessor :size
    attr_accessor :percent_progress
    attr_accessor :downloaded
    attr_accessor :uploaded
    attr_accessor :ratio
    attr_accessor :upload_speed
    attr_accessor :download_speed
    attr_accessor :eta
    attr_accessor :label
    attr_accessor :peers_connected
    attr_accessor :peers_in_swarm
    attr_accessor :seeds_connected
    attr_accessor :seeds_in_swarm
    attr_accessor :availability
    attr_accessor :torrent_queue_order
    attr_accessor :remaining
    attr_accessor :unk1
    attr_accessor :unk2
    attr_accessor :msg
    attr_accessor :unk4
    attr_accessor :unk5
    attr_accessor :unk6
    attr_accessor :unk7
    attr_accessor :folder
    attr_accessor :unk8

    ###
    # TorrentData constructor
    #
    # torrent:: Array of torrent data
    #
    def initialize(torrent)
      $LOG.debug "TorrentData::initialize"

      @hash                 = torrent[0]
      @status               = torrent[1]
      @name                 = torrent[2]
      @size                 = torrent[3]
      @percent_progress     = torrent[4]
      @downloaded           = torrent[5]
      @uploaded             = torrent[6]
      @ratio                = torrent[7]
      @upload_speed         = torrent[8]
      @download_speed       = torrent[9]
      @eta                  = torrent[10]
      @label                = torrent[11]
      @peers_connected      = torrent[12]
      @peers_in_swarm       = torrent[13]
      @seeds_connected      = torrent[14]
      @seeds_in_swarm       = torrent[15]
      @availability         = torrent[16]
      @torrent_queue_order  = torrent[17]
      @remaining            = torrent[18]
      @unk1                 = torrent[19]
      @unk2                 = torrent[20]
      @msg                  = torrent[21]
      @unk4                 = torrent[22]
      @unk5                 = torrent[23]
      @unk6                 = torrent[24]
      @unk7                 = torrent[25]
      @folder               = torrent[26]
      @unk8                 = torrent[27]

    end

    ###
    # Set the verbose flag
    #
    # arg:: verbose mode if true
    #
    def verbose=(arg)
      $LOG.debug "TorrentData::verbose=( #{arg} )"
      @verbose = arg
    end

    ###
    # Convert the data to a hash
    #
    # *Args*
    #
    # +arg1+ -- description
    #
    # +arg2+ -- description
    #
    # *Returns*
    #
    # Hash of torrent data
    #
    def to_hsh
      hsh = {}
      hsh["hash"] = @hash
      hsh["status"] = @status
      hsh["name"] = @name
      hsh["size"] = @size
      hsh["percent_progress"] = @percent_progress
      hsh["downloaded"] = @downloaded
      hsh["uploaded"] = @uploaded
      hsh["ratio"] = @ratio
      hsh["upload_speed"] = @upload_speed
      hsh["download_speed"] = @download_speed
      hsh["eta"] = @eta
      hsh["label"] = @label
      hsh["peers_connected"] = @peers_connected
      hsh["peers_in_swarm"] = @peers_in_swarm
      hsh["seeds_connected"] = @seeds_connected
      hsh["seeds_in_swarm"] = @seeds_in_swarm
      hsh["availability"] = @availability
      hsh["torrent_queue_order"] = @torrent_queue_order
      hsh["remaining"] = @remaining
      hsh["unk1"] = @unk1
      hsh["unk2"] = @unk2
      hsh["msg"] = @msg
      hsh["unk4"] = @unk4
      hsh["unk5"] = @unk5
      hsh["unk6"] = @unk6
      hsh["unk7"] = @unk7
      hsh["folder"] = @folder
      hsh["unk8"] = @unk8

      hsh
    end
  end # class TorrentData
end # module TorrentProcessor::Service::UTorrent
