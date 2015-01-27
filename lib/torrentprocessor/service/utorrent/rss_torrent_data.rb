##############################################################################
# File::    rssdata.rb
# Purpose:: RSSData objects encapsulate data related to RSS Feeds
#
# Author::    Jeff McAffee 02/25/2012
# Copyright:: Copyright (c) 2012, kTech Systems LLC. All rights reserved.
# Website::   http://ktechsystems.com
##############################################################################

module TorrentProcessor::Service::UTorrent

  class RSSTorrentData

    attr_accessor :name1
    attr_accessor :torrent_name
    attr_accessor :url
    attr_accessor :unk1
    attr_accessor :unk2
    attr_accessor :unk3
    attr_accessor :unk4
    attr_accessor :unk5
    attr_accessor :unk6
    attr_accessor :unk7
    attr_accessor :unk8
    attr_accessor :downloaded

    FIELD_COUNT = 12

    ###
    # Constructor
    #
    # *Args*
    #
    # +tdata+ -- Array containing RSS torrent data
    #
    def initialize(tdata)
      raise "Unexpected number of fields in torrent data array. Expecting #{FIELD_COUNT}, received #{tdata.length}." unless tdata.length == FIELD_COUNT

      @name1        = tdata[0]
      @torrent_name = tdata[1]
      @url          = tdata[2]
      @unk1         = tdata[3]
      @unk2         = tdata[4]
      @unk3         = tdata[5]
      @unk4         = tdata[6]
      @unk5         = tdata[7]
      @unk6         = tdata[8]
      @unk7         = tdata[9]
      @unk8         = tdata[10]
      @downloaded   = tdata[11]

    end

    ###
    # Convert the data to a hash
    #
    # *Returns*
    #
    # Hash of torrent data
    #
    def to_hsh
      hsh = {}
      hsh["name1"]        = @name1
      hsh["torrent_name"] = @torrent_name
      hsh["url"]          = @url
      hsh["unk1"]         = @unk1
      hsh["unk2"]         = @unk2
      hsh["unk3"]         = @unk3
      hsh["unk4"]         = @unk4
      hsh["unk5"]         = @unk5
      hsh["unk6"]         = @unk6
      hsh["unk7"]         = @unk7
      hsh["unk8"]         = @unk8
      hsh["downloaded"]   = @downloaded

      hsh
    end
  end # class RSSTorrentData


  class RSSFeed

    attr_accessor :unk1
    attr_accessor :unk2
    attr_accessor :unk3
    attr_accessor :unk4
    attr_accessor :unk5
    attr_accessor :unk6
    attr_accessor :feed_name
    attr_accessor :feed_url
    attr_accessor :unk7
    attr_accessor :torrents   # Array RSSTorrentData objects containing torrent info.

    FIELD_COUNT = 9           # feed_name and feed_url are bundled together in the data from uTorrent.

    ###
    # Constructor
    #
    # *Args*
    #
    # +rss_feed+ -- RSS Feed data in array format
    #
    def initialize(rss_feed)
      raise "Unexpected number of fields in rssfeed array. Expecting #{FIELD_COUNT}, received #{rss_feed.length}." unless rss_feed.length == FIELD_COUNT

      @unk1       = rss_feed[0]
      @unk2       = rss_feed[1]
      @unk3       = rss_feed[2]
      @unk4       = rss_feed[3]
      @unk5       = rss_feed[4]
      @unk6       = rss_feed[5]

      name_url    = rss_feed[6].split("|")
        @feed_name  = name_url[0]
        @feed_url   = name_url[1]

      @unk7       = rss_feed[7]

      @torrents   = []
      tdata = rss_feed[8]
      tdata.each do |t|
        @torrents << RSSTorrentData.new(t)
      end # each t

    end # initialize(rss_feed)

    ###
    # Convert the data to a hash
    #
    # *Returns*
    #
    # Hash of torrent data
    #
    def to_hsh
      hsh = {}
      hsh["unk1"] = @unk1
      hsh["unk2"] = @unk2
      hsh["unk3"] = @unk3
      hsh["unk4"] = @unk4
      hsh["unk5"] = @unk5
      hsh["unk6"] = @unk6
      hsh["feed_name"] = @feed_name
      hsh["feed_url"] = @feed_url
      hsh["unk7"] = @unk7
      hsh["torrents"] = @torrents

      hsh
    end
  end # class RSSFeed



  class RSSFilter

    attr_accessor :id
    attr_accessor :filter_modifier    # Bitfield
    attr_accessor :feed_name
    attr_accessor :include_filter
    attr_accessor :exclude_filter
    attr_accessor :dest_dir       # This will override the default set in uTorrent settings
    attr_accessor :unk2
    attr_accessor :quality        # Bit field
    attr_accessor :label
    attr_accessor :minimum_interval
    attr_accessor :unk3
    attr_accessor :unk4
    attr_accessor :unk5
    attr_accessor :episode_filter
    attr_accessor :use_episode_filter   # True/False
    attr_accessor :unk6                 # True/False

    FIELD_COUNT = 16

    # Constants

        # Filter Modifiers
        class FilterModifier
          MATCH_ORIGINAL_NAME  = 1<<1
          HIGH_PRIORITY        = 1<<2
          SMART_FILTER         = 1<<3
          NO_AUTO_DOWNLOAD     = 1<<4

        end # class FilterModifier


        # Quality Types
        class Quality
          ALL     = -1
          DSRIP   = 1<<4
          DVBRIP  = 1<<5
          DVDR    = 1<<9
          DVDSCR  = 1<<10
          DVDRIP  = 1<<2
          HDTV    = 1<<0
          HRHDTV  = 1<<7
          HRPDTV  = 1<<8
          PDTV    = 1<<6
          SATRIP  = 1<<15
          SVCD    = 1<<3
          TVRIP   = 1<<1
          I1080   = 1<<12
          P720    = 1<<11
          WEBRIP  = 1<<14

        end # class Quality


        # Minimum Interval Types
        class MinimumInterval
          MATCH_ALWAYS  = 0
          MATCH_ONCE    = 1
          HOURS12       = 2
          DAY1          = 3
          DAY2          = 4
          DAY3          = 5
          DAY4          = 6
          WEEK          = 7

        end # class MinimumInterval

    ###
    # Constructor
    #
    # *Args*
    #
    # +rssfilter+ -- RSS Filter array object
    #
    def initialize(rssfilter)
      raise "Unexpected number of fields in rssfilter array. Expecting #{FIELD_COUNT}, received #{rssfilter.length}." unless rssfilter.length == FIELD_COUNT

      @id                 = rssfilter[0]
      @filter_modifier    = rssfilter[1]
      @feed_name          = rssfilter[2]
      @include_filter     = rssfilter[3]
      @exclude_filter     = rssfilter[4]
      @dest_dir           = rssfilter[5]
      @unk2               = rssfilter[6]
      @quality            = rssfilter[7]
      @label              = rssfilter[8]
      @minimum_interval   = rssfilter[9]
      @unk3               = rssfilter[10]
      @unk4               = rssfilter[11]
      @unk5               = rssfilter[12]
      @episode_filter     = rssfilter[13]
      @use_episode_filter = rssfilter[14]
      @unk6               = rssfilter[15]

    end

    ###
    # Convert the data to a hash
    #
    # *Returns*
    #
    # Hash of torrent data
    #
    def to_hsh
      hsh = {}
      hsh["id"]                 = @id
      hsh["filter_modifier"]    = filter_modifier_to_text()
      hsh["feed_name"]          = @feed_name
      hsh["include_filter"]     = @include_filter
      hsh["exclude_filter"]     = @exclude_filter
      hsh["dest_dir"]           = @dest_dir
      hsh["unk2"]               = @unk2
      hsh["quality"]            = quality_to_text()
      hsh["label"]              = @label
      hsh["minimum_interval"]   = minimum_interval_to_text()
      hsh["unk3"]               = @unk3
      hsh["unk4"]               = @unk4
      hsh["unk5"]               = @unk5
      hsh["episode_filter"]     = @episode_filter
      hsh["use_episode_filter"] = @use_episode_filter
      hsh["unk6"]               = @unk6

      hsh
    end

    # Convert a filter_modifier value to a text representation
    #
    # *Returns*
    #
    # text representation of @filter_modifier
    #
    def filter_modifier_to_text
      ftypes = []
      ftypes << "Download as High Priority" if ((@filter_modifier & FilterModifier::HIGH_PRIORITY)        != 0)
      ftypes << "Smart Filter"              if ((@filter_modifier & FilterModifier::SMART_FILTER)         != 0)
      ftypes << "Match Original Name"       if ((@filter_modifier & FilterModifier::MATCH_ORIGINAL_NAME)  != 0)
      ftypes << "No Automatic Download"     if ((@filter_modifier & FilterModifier::NO_AUTO_DOWNLOAD)     != 0)

      ftypes << "None" if ftypes.empty?
      ftypes.join(" | ")
    end

    ###
    # Convert a quality value to a text representation
    #
    # *Returns*
    #
    # text representation of @quality
    #
    def quality_to_text
      return "ALL" unless @quality != -1

      qtypes = []
      qtypes << "DSRip"   if ((@quality & Quality::DSRIP)   != 0)
      qtypes << "DVBRip"  if ((@quality & Quality::DVBRIP)  != 0)
      qtypes << "DVDR"    if ((@quality & Quality::DVDR)    != 0)
      qtypes << "DVDRip"  if ((@quality & Quality::DVDRIP)  != 0)
      qtypes << "DVDScr"  if ((@quality & Quality::DVDSCR)  != 0)
      qtypes << "HDTV"    if ((@quality & Quality::HDTV)    != 0)
      qtypes << "HR.HDTV" if ((@quality & Quality::HRHDTV)  != 0)
      qtypes << "HR.PDTV" if ((@quality & Quality::HRPDTV)  != 0)
      qtypes << "PDTV"    if ((@quality & Quality::PDTV)    != 0)
      qtypes << "SatRip"  if ((@quality & Quality::SATRIP)  != 0)
      qtypes << "SVCD"    if ((@quality & Quality::SVCD)    != 0)
      qtypes << "TVRip"   if ((@quality & Quality::TVRIP)   != 0)
      qtypes << "WebRip"  if ((@quality & Quality::WEBRIP)  != 0)
      qtypes << "720p"    if ((@quality & Quality::P720)    != 0)
      qtypes << "1080i"   if ((@quality & Quality::I1080)   != 0)

      qtypes << "Unknown (#{@quality})" if qtypes.empty?
      qtypes.join(" | ")
    end

    ###
    # Convert a minimum_interval value to a text representation
    #
    # *Returns*
    #
    # text representation of @minimum_interval
    #
    def minimum_interval_to_text
      return "Match Always" if @minimum_interval == MinimumInterval::MATCH_ALWAYS
      return "Match Once"   if @minimum_interval == MinimumInterval::MATCH_ONCE
      return "12 Hours"     if @minimum_interval == MinimumInterval::HOURS12
      return "1 Day"        if @minimum_interval == MinimumInterval::DAY1
      return "2 Days"       if @minimum_interval == MinimumInterval::DAY2
      return "3 Days"       if @minimum_interval == MinimumInterval::DAY3
      return "4 Days"       if @minimum_interval == MinimumInterval::DAY4
      return "1 Week"       if @minimum_interval == MinimumInterval::WEEK

      return "Unknown"
    end
  end # class RSSFilter
end # module TorrentProcessor::Service::UTorrent
