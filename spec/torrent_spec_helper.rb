##############################################################################
# File::    torrent_spec_helper.rb
# Purpose:: Spec helper methods for providing torrent data
# 
# Author::    Jeff McAffee 02/05/2014
# Copyright:: Copyright (c) 2014, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentSpecHelper

  def self.utorrent_settings_data
    [
      ["webui.uconnect_toolbar_ever", 1, "true", {"access"=>"R"}]
    ]
  end

  def self.utorrent_job_properties_data
    {
      "build" => 30303,
      "props" =>
        [
          {
            "hash" => "AC17F4207E045D532827013C122F6A6300E007E9",
            "trackers" => "http://announce.torrentday.com:60000/2199fba8b71c72ef8ca3b8ab9514659d/announce\r\n",
            "ulrate" => 0,
            "dlrate" => 0,
            "superseed" => 0,
            "dht" => -1,
            "pex" => -1,
            "seed_override" => 1,
            "seed_ratio" => 2500,
            "seed_time" => 0,
            "ulslots" => 0,
            "seed_num" => 0,
          }
        ]
    }
  end

  def self.utorrent_torrent_list_data
    [
      [
        "AC17F4207E045D532827013C122F6A6300E007E9",
        136,
        "Horizon.S52E16.Defeating.The.Hackers.REPACK.HDTV.XviD-AFG",
        520023045,
        1000,
        520023045,
        0,
        0,
        0,
        0,
        0,
        "TV",
        0,
        0,
        0,
        0,
        65536,
        -1,
        0,
        "",
        "",
        "Finished",
        "28f2b15b",
        1389666000,
        1389666613,
        "",
        "C:\\XMBC-Apps\\Torrents\\downloads-completed\\Horizon.S52E16.Defeating.The.Hackers.REPACK.HDTV.XviD-AFG",
        0,
        "B8698237"
      ],
      [
        "D183C92BE6219B5078A1DC22895157144500AC0A",
        201,
        "Burn.Notice.S04E06.720p.HDTV.x264-IMMERSE",
        1174149774,
        1000,
        1173723790,
        0,
        0,
        0,
        0,
        -1,
        "TV",
        0,
        0,
        0,
        0,
        65536,
        -1,
        0,
        "",
        "",
        "Seeding",
        "28f2b143",
        1388958086,
        1390488444,
        "",
        "C:\\XMBC-Apps\\Torrents\\downloads-completed\\Burn.Notice.S04E06.720p.HDTV.x264-IMMERSE",
        0,
        "D144F9CC"
      ]
    ]
  end

  def self.utorrent_torrents_data
    the_torrents = {}
    utorrent_torrent_list_data.each do |i|
      tdata = TorrentProcessor::Service::UTorrent::TorrentData.new(i)
      the_torrents[tdata.hash] = tdata
    end
    the_torrents
  end
end # module TorrentSpecHelper

